//
//  AMBBatchBLControllerAgent.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBBatchBLControllerAgent.h"
#import "AMBBatchBLController.h"

@interface AMBBatchBLControllerAgent ()

@property (nonatomic, strong) NSMutableArray<AMBBatchBLController *> *requestArray;

@end

@implementation AMBBatchBLControllerAgent

#pragma mark -
#pragma mark ==== 系统方法 ====
#pragma mark -

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.requestArray = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -

/**
 创建AMBBatchBLControllerAgent单例
 
 @return 返回AMBBatchBLControllerAgent实例
 */
+ (AMBBatchBLControllerAgent *)sharedAgent
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

/**
 添加AMBBatchBLController实例
 
 @param blController AMBBatchBLController实例
 */
- (void)addBatchBLController:(AMBBatchBLController *)blController
{
    @synchronized(self) {
        
        if (blController)
        {
            [_requestArray addObject:blController];
        }
    }
}

/**
 移除AMBBatchBLController实例
 
 @param blController AMBBatchBLController实例
 */
- (void)removeBatchBLController:(AMBBatchBLController *)blController
{
    @synchronized(self) {
        
        if (blController)
        {
            [_requestArray removeObject:blController];
        }
    }
}

@end
