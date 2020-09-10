//
//  AMBBatchBLControllerAgent.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMBBatchBLController;

/**
 用于缓存AMBBatchBLController实例
 */
@interface AMBBatchBLControllerAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建AMBBatchBLControllerAgent单例
 
 @return 返回AMBBatchBLControllerAgent实例
 */
+ (AMBBatchBLControllerAgent *)sharedAgent;

/**
 添加AMBBatchBLController实例
 
 @param blController AMBBatchBLController实例
 */
- (void)addBatchBLController:(AMBBatchBLController *)blController;

/**
 移除AMBBatchBLController实例
 
 @param blController AMBBatchBLController实例
 */
- (void)removeBatchBLController:(AMBBatchBLController *)blController;

@end
