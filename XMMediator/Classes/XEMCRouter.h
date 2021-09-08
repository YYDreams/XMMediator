//
//  XEMCRouter.h
//  Pods-TestAUI
//
//  Created by xiaoemac on 2019/10/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XEMCRouter : NSObject

/// 调用当前app某个对象方法
/// @param methodname 方法名称
/// @param params 方法参数，可以为nil，方法最多只能传入一个参数
/// @param sender 调用方法的当前对象
/// @param fcode 当前app的特征码
+ (void)callMethod:(NSString *)methodname
            params:(nullable id)params
            sender:(id)sender
             fcode:(NSString *)fcode;

/// 寻找当前app需要的VC视图
/// @param className 视图类名称
/// @param fcode 当前app的特征码
+ (_Nullable id)vc:(NSString *)className
             fcode:(NSString *)fcode;

/// 寻找当前app需要的VC视图
/// @param className 视图类名称
/// @param swiftModule 如果是Swift类，需要填当前模块名称, 否则传nil
/// @param fcode 当前app的特征码
+ (_Nullable id)vc:(NSString *)className
            module:(nullable NSString *)swiftModule
             fcode:(NSString *)fcode;

@end

NS_ASSUME_NONNULL_END
