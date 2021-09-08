//
//  XEMediator.h
//  XEMediator
//
//  Created by Jacky on 19/5/08.
//  Copyright © 2019年 casa. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kXEMediatorParamsKeySwiftTargetModuleName;

@interface XEMediator : NSObject

/// 区分不同 APP
@property (nonatomic, strong) NSString *appCode;

/// 单例
+ (instancetype)shared;

/// 本地组件调用入口
/// @param targetName 目标
/// @param actionName 方法
/// @param params 参数
/// @param shouldCacheTarget 是否缓存目标
- (id)performTarget:(NSString *)targetName
             action:(NSString *)actionName
             params:(NSDictionary *)params
             shouldCacheTarget:(BOOL)shouldCacheTarget;

/// 释放缓存的目标
/// @param targetName 目标名称
- (void)releaseCachedTargetWithTargetName:(NSString *)targetName;

@end
