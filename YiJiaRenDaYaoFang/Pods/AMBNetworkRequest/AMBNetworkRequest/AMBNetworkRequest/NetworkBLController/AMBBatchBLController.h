//
//  AMBBatchBLController.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMBBaseBLController;
@class AMBBatchBLController;

/**
 请求数据后的回调，若批量请求所有接口都请求成功，则failedBLController为nil，否则为最后一个请求失败的实例
 */
typedef void(^AMBRequestBatchCompletionBlock)(AMBBatchBLController *batchBLController, AMBBaseBLController *failedBLController);

/**
 用于发送批量的网络请求
 */
@interface AMBBatchBLController : NSObject<NSCopying>

/**
 当requestArray中的某个接口请求失败后是否要继续走完所有请求，默认为NO
 */
@property (nonatomic, assign) BOOL isRequestFailContinue;

/**
 存储接口对象
 */
@property (nonatomic, strong, readonly) NSArray<AMBBaseBLController *> *requestArray;

/**
 初始化AMBBatchBLController
 
 @param requestArray 接口对象数组
 @return 返回AMBBatchBLController实例
 */
- (instancetype)initWithRequestArray:(NSArray<AMBBaseBLController *> *)requestArray;

/**
 设置成功和失败的回调并开始接口请求
 
 @param successBlock 请求成功的回调(若isRequestFailContinue为YES，就算是有请求失败，也走该回调)
 @param failureBlock 请求失败的回调(若isRequestFailContinue为NO，有请求失败的话走该回调)
 */
- (void)startWithCompletionBlockWithSuccess:(AMBRequestBatchCompletionBlock)successBlock failure:(AMBRequestBatchCompletionBlock)failureBlock;

@end
