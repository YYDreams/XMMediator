//
//  XENoTargetActionProcessor.h
//  XEMediator
//
//  Created by xiaoemac on 2019/5/13.
//  Copyright © 2019年 xiaoemac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XENoTargetActionProcessor : NSObject

/**
 统一响应无法查询的组件方法
 
 @param params 参数
 */
- (void)responseNoTargetAction:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
