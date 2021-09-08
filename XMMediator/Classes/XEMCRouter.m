//
//  XEMCRouter.m
//  Pods-TestAUI
//
//  Created by xiaoemac on 2019/10/15.
//

#import "XEMCRouter.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

@implementation XEMCRouter

/// 调用当前app某个对象方法
/// @param methodname 方法名称
/// @param params 方法参数，可以为nil，方法最多只能传入一个参数
/// @param sender 调用方法的当前对象
/// @param fcode 当前app的特征码
+ (void)callMethod:(NSString *)methodname
            params:(nullable id)params
            sender:(id)sender
             fcode:(NSString *)fcode
                    
{
    [self runTests:sender];
    
    if (sender &&
        [methodname isKindOfClass:[NSString class]] &&
        [fcode isKindOfClass:[NSString class]]) {
        NSString *mname = [NSString stringWithFormat:@"%@",methodname];
        if (params && ![mname hasSuffix:@":"]) {
            mname = [NSString stringWithFormat:@"%@:",mname];
        }
        NSString *fixmethodname = [NSString stringWithFormat:@"%@_%@",[fcode uppercaseString],mname];
        SEL sel = NSSelectorFromString(fixmethodname);
        
        if ([sender respondsToSelector:sel]) {
            SuppressPerformSelectorLeakWarning(
                [sender performSelectorOnMainThread:sel withObject:params waitUntilDone:NO];
            );
            
            return;
        }
        fixmethodname = mname;
        sel = NSSelectorFromString(fixmethodname);
        if ([sender respondsToSelector:sel]) {
            SuppressPerformSelectorLeakWarning(
                [sender performSelectorOnMainThread:sel withObject:params waitUntilDone:NO];
            );
            return;
        }
    }
    
}

+ (void)runTests:(id)sender

{


    
    

    unsigned int count;

//    Method *methods = class_copyMethodList([sender class], &count);
//
//    for (int i = 0; i < count; i++)
//
//    {
//
//        Method method = methods[i];
//
//        SEL selector = method_getName(method);
//
//        NSString *name = NSStringFromSelector(selector);
//
////        if ([name hasPrefix:@"test"])
//
//        NSLog(@"方法 名字 ==== %@",name);
//
//        if (name)
//
//        {
//
//            //avoid arc warning by using c runtime
//
////            objc_msgSend(self, selector);
//
//        }
//
//
//
////        NSLog(@"Test '%@' completed successfuly", [name substringFromIndex:4]);
//
//    }
//
//
    //获取属性列表
    objc_property_t *propertyList = class_copyPropertyList([sender class], &count);
    for (unsigned int i=0; i<count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSLog(@"property----="">%@", [NSString stringWithUTF8String:propertyName]);
    }
    
//    //获取方法列表
//    Method *methodList = class_copyMethodList([sender class], &count);
//    for (unsigned int i = 0; i<count; i++) {
//        Method method = methodList[i];
//        NSLog(@"method----="">%@", NSStringFromSelector(method_getName(method)));
//
//        const char *name = sel_getName(method_getName(method));
//        NSLog(@"RuntimeCategoryClass's method: %s", name);
////        if (strcmp(name, sel_getName(@selector(method2)))) {
////            NSLog(@"分类方法method2在objc_class的方法列表中");
////        }
//    }
//
    
    //获取方法列表
    Method *methodList = class_copyMethodList([sender class], &count);
    for (unsigned int i = 0; i<count; i++) {
        Method method = methodList[i];
        NSLog(@"method----="">%@", NSStringFromSelector(method_getName(method)));
    }
    
    //获取成员变量列表
    Ivar *ivarList = class_copyIvarList([sender class], &count);
    for (unsigned int i = 0; i<count; i++) {
        Ivar myIvar = ivarList[i];
        const char *ivarName = ivar_getName(myIvar);
        NSLog(@"ivar----="">%@", [NSString stringWithUTF8String:ivarName]);
    }

    
    //获取协议列表
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList([sender class], &count);
    for (unsigned int i = 0; i<count; i++) {
        Protocol *myProtocal = protocolList[i];
        const char *protocolName = protocol_getName(myProtocal);
        NSLog(@"protocol----="">%@", [NSString stringWithUTF8String:protocolName]);
    }
    

}
/// 寻找当前app需要的VC视图
/// @param className 视图类名称
/// @param fcode 当前app的特征码
+ (_Nullable id)vc:(NSString *)className
             fcode:(NSString *)fcode
{
    return [XEMCRouter vc:className module:nil fcode:fcode];
}

/// 寻找当前app需要的VC视图
/// @param className 视图类名称
/// @param swiftModule 如果是Swift类，需要填当前模块名称
/// @param fcode 当前app的特征码
+ (_Nullable id)vc:(NSString *)className
            module:(nullable NSString *)swiftModule
             fcode:(NSString *)fcode
{
    if ([className isKindOfClass:[NSString class]] &&
        [fcode isKindOfClass:[NSString class]]) {
        NSString *moduleString = @"";
        if ([swiftModule isKindOfClass:[NSString class]] &&
            [swiftModule length] > 0) {
            moduleString = [NSString stringWithFormat:@"%@.",swiftModule];
        }
        //先寻找app特征码_vc类名的class
        Class fixclass = NSClassFromString([NSString stringWithFormat:@"%@%@_%@",moduleString,[fcode uppercaseString],className]);
        id obj = [[fixclass alloc] init];
        if (obj && [obj isKindOfClass: [UIViewController class]]) {
            return obj;
        }
        Class class = NSClassFromString([NSString stringWithFormat:@"%@%@",moduleString,className]);
        obj =  [[class alloc] init];
        if (obj && [obj isKindOfClass: [UIViewController class]]) {
            return obj;
        }
    }
    return nil;
}

@end
