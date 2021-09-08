//
//  XEMediator.h
//  XEMediator
//
//  Created by Jacky on 19/5/08.
//  Copyright © 2019年 casa. All rights reserved.
//

#import "XEMediator.h"
#import <objc/runtime.h>
#import "XENoTargetActionProcessor.h"

NSString * const kXEMediatorParamsKeySwiftTargetModuleName = @"kXEMediatorParamsKeySwiftTargetModuleName";

@interface XEMediator ()

@property (nonatomic, strong) NSMutableDictionary *cachedTarget;

// 类前缀优先调用
@property (nonatomic, strong) NSString *priorityCallPrefix;

@end

@implementation XEMediator

#pragma mark - public methods

+ (instancetype)shared
{
    static XEMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[XEMediator alloc] init];
    });
    mediator.priorityCallPrefix = @"C";
    return mediator;
}

/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */

- (id)performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *urlString = [url query];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget
{
    NSString *swiftModuleName = params[kXEMediatorParamsKeySwiftTargetModuleName];
    
    // generate action
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    SEL action = NSSelectorFromString(actionString);
    
    // generate target X
    NSObject *targetX = [self generateTargetWithSwiftModuleName:swiftModuleName
                                                     targetName:targetName
                                              shouldCacheTarget:shouldCacheTarget
                                                         prefix:self.priorityCallPrefix];
    
    
    // 调用高优先级类 (定制类)
    if ([targetX respondsToSelector:action]) {
        return [self safePerformAction:action target:targetX params:params];
    }
    
    // generate target
    NSObject *target = [self generateTargetWithSwiftModuleName:swiftModuleName
                                                    targetName:targetName
                                             shouldCacheTarget:shouldCacheTarget
                                                        prefix:@""];
        
    // 调用低优先级类 (主题类)
    if ([target respondsToSelector:action]) {
        // 调用通用代码
        return [self safePerformAction:action target:target params:params];
    }
    
    // 处理无法响应的情况
    NSString *errorTargetClassString = [NSString stringWithFormat:@"%@.Target_%@", swiftModuleName, targetName];;
    
    if (target == nil && targetX == nil) {
        // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
        [self NoTargetActionResponseWithTargetString:errorTargetClassString selectorString:actionString originParams:params];
        return nil;
    }

    // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
    SEL notFoundAction = NSSelectorFromString(@"notFound:");
    if ([target respondsToSelector:action]) {
        return [self safePerformAction:notFoundAction target:target params:params];
    } else {
        // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
        [self NoTargetActionResponseWithTargetString:errorTargetClassString selectorString:actionString originParams:params];
        [self.cachedTarget removeObjectForKey:errorTargetClassString];
        return nil;
    }
}

- (void)releaseCachedTargetWithTargetName:(NSString *)targetName
{
    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    [self.cachedTarget removeObjectForKey:targetClassString];
}


#pragma mark - target & action

- (NSObject *)generateTargetWithSwiftModuleName:(NSString *)swiftModuleName
                                     targetName:(NSString * )targetName
                              shouldCacheTarget: (BOOL)shouldCacheTarget
                                         prefix:(NSString *)prefix
{
    NSString *targetXClassString = nil;

    if (swiftModuleName.length > 0) {
        targetXClassString = [NSString stringWithFormat:@"%@.%@Target_%@", swiftModuleName, prefix, targetName];
    } else {
        targetXClassString = [NSString stringWithFormat:@"%@Target_%@", prefix, targetName];
    }

    NSObject *targetX = self.cachedTarget[targetXClassString];
    if (targetX == nil) {
        Class targetXClass = NSClassFromString(targetXClassString);
        targetX = [[targetXClass alloc] init];
    }

    // 兼容通过pod引入的swift组件库
    if (targetX == nil &&
        swiftModuleName.length > 0 &&
        ![swiftModuleName hasSuffix:@"_swift"]) {
        
        NSString *swiftModuleXName2 = [NSString stringWithFormat:@"%@_swift",swiftModuleName];
        
        if (self.priorityCallPrefix.length > 0) {
            targetXClassString = [NSString stringWithFormat:@"%@.Target_%@_%@", swiftModuleXName2, targetName, prefix];
        }
        
        targetX = self.cachedTarget[targetXClassString];
        if (targetX == nil) {
            Class targetXClass = NSClassFromString(targetXClassString);
            targetX = [[targetXClass alloc] init];
        }
    }
    
    if (shouldCacheTarget) {
        self.cachedTarget[targetXClassString] = targetX;
    }
    
    return targetX;
}
                
                


#pragma mark - private methods
- (void)NoTargetActionResponseWithTargetString:(NSString *)targetString selectorString:(NSString *)selectorString originParams:(NSDictionary *)originParams
{
    SEL action = NSSelectorFromString(@"responseNoTargetAction:");
    NSObject *target = [[NSClassFromString(@"XENoTargetActionProcessor") alloc] init];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"originParams"] = originParams;
    params[@"targetString"] = targetString;
    params[@"selectorString"] = selectorString;
    
    [self safePerformAction:action target:target params:params];
}

- (id)safePerformAction:(SEL)action target:(NSObject *)target params:(NSDictionary *)params
{
    NSMethodSignature* methodSig = [target methodSignatureForSelector:action];
    if(methodSig == nil) {
        return nil;
    }
    const char* retType = [methodSig methodReturnType];

    if (strcmp(retType, @encode(void)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        return nil;
    }

    if (strcmp(retType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(CGFloat)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(NSUInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}

#pragma mark - getters and setters
- (NSMutableDictionary *)cachedTarget
{
    if (_cachedTarget == nil) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

@end
