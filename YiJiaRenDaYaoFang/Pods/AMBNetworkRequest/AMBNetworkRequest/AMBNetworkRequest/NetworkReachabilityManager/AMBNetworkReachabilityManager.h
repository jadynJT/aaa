//
//  AMBNetworkReachabilityManager.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 网络变化通知，需要监听网络变化的话，可以观察该通知
 */
FOUNDATION_EXPORT NSString * const AMBNetworkingReachabilityDidChangeNotification;

/**
 网络变化数据字段，监听网络变化时，userInfo数据中的字段名
 */
FOUNDATION_EXPORT NSString * const AMBNetworkingReachabilityNotificationStatusItem;

/**
 网络状态类别
 */
typedef NS_ENUM(NSInteger, AMBNetworkReachabilityStatus)
{
    AMBNetworkReachabilityStatusUnknown          = -1,//未知网络
    AMBNetworkReachabilityStatusNotReachable      = 0,//无网络
    AMBNetworkReachabilityStatusReachableViaWWAN  = 1,//手机网络
    AMBNetworkReachabilityStatusReachableViaWiFi  = 2,//wifi网络
};

/**
 网络状态监控类
 */
@interface AMBNetworkReachabilityManager : NSObject

/**
 当前网络状态
 */
@property (nonatomic, assign, readonly) AMBNetworkReachabilityStatus networkReachabilityStatus;

/**
 是否有网络，是为YES，否为NO
 */
@property (nonatomic, assign, readonly) BOOL reachable;

/**
 是否是wifi网络，是为YES，否为NO
 */
@property (nonatomic, assign, readonly) BOOL reachableViaWWAN;

/**
 是否是手机网络，是为YES，否为NO
 */
@property (nonatomic, assign, readonly) BOOL reachableViaWiFi;

/**
 创建AMBNetworkReachabilityManager单例
 
 @return 返回AMBNetworkReachabilityManager实例
 */
+ (AMBNetworkReachabilityManager *)sharedManager;

/**
 开启网络监听
 */
- (void)startMonitoring;

@end
