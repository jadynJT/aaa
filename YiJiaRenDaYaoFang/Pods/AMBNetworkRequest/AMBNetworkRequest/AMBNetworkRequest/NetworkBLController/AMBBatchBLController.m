//
//  AMBBatchBLController.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBBatchBLController.h"
#import "AMBBaseBLController.h"
#import "AMBBatchBLControllerAgent.h"

@interface AMBBatchBLController ()

@property (nonatomic, strong) NSArray<AMBBaseBLController *> *requestArray;
@property (nonatomic, strong) AMBBaseBLController *failedBLController;
@property (nonatomic) NSInteger finishedCount;
@property (nonatomic, copy) AMBRequestBatchCompletionBlock successBlock;
@property (nonatomic, copy) AMBRequestBatchCompletionBlock failureBlock;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation AMBBatchBLController

#pragma mark -
#pragma mark ==== 系统方法 ====
#pragma mark -

- (void)dealloc
{
#if DEBUG
    NSLog(@"%@接口请求实例释放，实例内存地址:<%p>", NSStringFromClass([self class]), self);
#endif
    
    [self cancelRequest];
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.isRequestFailContinue = NO;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSMutableArray *requestArray = [NSMutableArray array];
    
    [self.requestArray enumerateObjectsUsingBlock:^(AMBBaseBLController *obj, NSUInteger idx, BOOL *stop) {
        
        AMBBaseBLController *blController = [obj copy];
        [requestArray addObject:blController];
    }];
    
    AMBBatchBLController *blController = [[AMBBatchBLController alloc] initWithRequestArray:requestArray];
    blController.isRequestFailContinue = self.isRequestFailContinue;
    return blController;
}

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -

/**
 初始化AMBBatchBLController
 
 @param requestArray 接口对象数组
 @return 返回AMBBatchBLController实例
 */
- (instancetype)initWithRequestArray:(NSArray<AMBBaseBLController *> *)requestArray
{
    self = [self init];
    
    if (self)
    {
#if DEBUG
        NSLog(@"%@接口请求实例创建，实例内存地址:<%p>", NSStringFromClass([self class]), self);
#endif
        
        _finishedCount = 0;
        _requestArray = [requestArray copy];
        
        for (AMBBaseBLController *blController in _requestArray)
        {
            if (![blController isKindOfClass:[AMBBaseBLController class]])
            {
                [NSException raise:NSInvalidArgumentException format:@"requestArray数组元素需为AMBBaseBLController实例或其子类实例"];
                return nil;
            }
        }
    }
    
    return self;
}

/**
 设置成功和失败的回调并开始接口请求
 
 @param successBlock 请求成功的回调
 @param failureBlock 请求失败的回调
 */
- (void)startWithCompletionBlockWithSuccess:(AMBRequestBatchCompletionBlock)successBlock failure:(AMBRequestBatchCompletionBlock)failureBlock
{
    if (_finishedCount > 0)
    {
        [NSException raise:NSInvalidArgumentException format:@"批量请求已经开始"];
        return;
    }
    
    self.successBlock = successBlock;
    self.failureBlock = failureBlock;
    self.failedBLController = nil;
    [self start];
}

#pragma mark -
#pragma mark ==== 内部使用方法 ====
#pragma mark -

/**
 开启接口请求
 */
- (void)start
{
    __weak __typeof(self) weakSelf = self;
    [[AMBBatchBLControllerAgent sharedAgent] addBatchBLController:self];
    
    for (AMBBaseBLController *blController in _requestArray)
    {
        [blController startWithCompletionBlockWithSuccess:^(AMBBaseBLController *blController) {
            
            [weakSelf requestSuccess];
        } failure:^(AMBBaseBLController *blController) {
            
            weakSelf.failedBLController = blController;
            
            if (weakSelf.isRequestFailContinue)
            {
                [weakSelf requestSuccess];
            }
            else
            {
                [weakSelf requestFail];
            }
        }];
    }
}

/**
 请求成功
 */
- (void)requestSuccess
{
    [self.lock lock];
    self.finishedCount++;
    
    if (self.finishedCount == self.requestArray.count)
    {
        if (self.successBlock)
        {
            self.successBlock(self, self.failedBLController);
        }
        
        self.successBlock = nil;
        self.failureBlock = nil;
        [[AMBBatchBLControllerAgent sharedAgent] removeBatchBLController:self];
    }
    
    [self.lock unlock];
}

/**
 请求失败
 */
- (void)requestFail
{
    [self.lock lock];
    
    for (AMBBaseBLController *blController in self.requestArray)
    {
        [blController cancelRequest];
    }
    
    if (self.failureBlock)
    {
        self.failureBlock(self, self.failedBLController);
    }
    
    self.successBlock = nil;
    self.failureBlock = nil;
    [[AMBBatchBLControllerAgent sharedAgent] removeBatchBLController:self];
    [self.lock unlock];
}

/**
 取消请求
 */
- (void)cancelRequest
{
    for (AMBBaseBLController *blController in self.requestArray)
    {
        [blController cancelRequest];
    }
    
    _successBlock = nil;
    _failureBlock = nil;
    [[AMBBatchBLControllerAgent sharedAgent] removeBatchBLController:self];
}

#pragma mark -
#pragma mark ==== 数据初始化 ====
#pragma mark -

- (NSLock *)lock
{
    if (!_lock)
    {
        _lock = [[NSLock alloc] init];
    }
    
    return _lock;
}

@end
