//
//  AMBNetworkReachabilityManager.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBNetworkReachabilityManager.h"
#import "AFNetworkReachabilityManager.h"

NSString * const AMBNetworkingReachabilityDidChangeNotification = @"ambNetworkingReachabilityDidChangeNotification";
NSString * const AMBNetworkingReachabilityNotificationStatusItem = @"ambNetworkingReachabilityNotificationStatusItem";

@interface AMBNetworkReachabilityManager ()

@property (nonatomic, assign) AMBNetworkReachabilityStatus networkReachabilityStatus;
@property (nonatomic, assign) BOOL reachable;
@property (nonatomic, assign) BOOL reachableViaWWAN;
@property (nonatomic, assign) BOOL reachableViaWiFi;

@end

@implementation AMBNetworkReachabilityManager

#pragma mark -
#pragma mark ==== 系统方法 ====
#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChangeNotification:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    }
    
    return self;
}

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -

/**
 创建AMBNetworkReachabilityManager单例
 
 @return 返回AMBNetworkReachabilityManager实例
 */
+ (AMBNetworkReachabilityManager *)sharedManager
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

/**
 开启网络监听
 */
- (void)startMonitoring
{
    __weak __typeof(self) weakSelf = self;
    __weak AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        weakSelf.reachable = manager.reachable;
        weakSelf.reachableViaWWAN = manager.reachableViaWWAN;
        weakSelf.reachableViaWiFi = manager.reachableViaWiFi;
        
        switch (status)
        {
            case AFNetworkReachabilityStatusUnknown:
                weakSelf.networkReachabilityStatus = AMBNetworkReachabilityStatusUnknown;
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
                weakSelf.networkReachabilityStatus = AMBNetworkReachabilityStatusNotReachable;
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                weakSelf.networkReachabilityStatus = AMBNetworkReachabilityStatusReachableViaWWAN;
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                weakSelf.networkReachabilityStatus = AMBNetworkReachabilityStatusReachableViaWiFi;
                break;
                
            default:
                break;
        }
    }];
    
    [manager startMonitoring];
}

#pragma mark -
#pragma mark ==== 内部使用方法 ====
#pragma mark -

/**
 网络变化回调

 @param notification 通知
 */
- (void)reachabilityDidChangeNotification:(NSNotification *)notification
{
    AMBNetworkReachabilityStatus status;
    
    switch ([notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue])
    {
        case AFNetworkReachabilityStatusUnknown:
            status = AMBNetworkReachabilityStatusUnknown;
            break;
            
        case AFNetworkReachabilityStatusNotReachable:
            status = AMBNetworkReachabilityStatusNotReachable;
            break;
            
        case AFNetworkReachabilityStatusReachableViaWWAN:
            status = AMBNetworkReachabilityStatusReachableViaWWAN;
            break;
            
        case AFNetworkReachabilityStatusReachableViaWiFi:
            status = AMBNetworkReachabilityStatusReachableViaWiFi;
            break;
            
        default:
            status = AMBNetworkReachabilityStatusUnknown;
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:AMBNetworkingReachabilityDidChangeNotification object:nil userInfo:@{AMBNetworkingReachabilityNotificationStatusItem : @(status)}];
    });
}

@end
