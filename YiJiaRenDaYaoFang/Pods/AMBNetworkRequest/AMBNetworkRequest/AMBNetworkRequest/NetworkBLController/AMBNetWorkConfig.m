//
//  AMBNetWorkConfig.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBNetWorkConfig.h"
#import "YTKNetworkConfig.h"

@implementation AMBNetWorkConfig

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -

/**
 创建AMBNetWorkConfig单例
 
 @return 返回AMBNetWorkConfig实例
 */
+ (AMBNetWorkConfig *)sharedNetWorkConfig
{
    static AMBNetWorkConfig *sharedNetWorkConfig;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedNetWorkConfig = [[self alloc] init];
    });
    
    return sharedNetWorkConfig;
}

#pragma mark -
#pragma mark ==== 数据初始化 ====
#pragma mark -

- (void)setBaseUrl:(NSString *)baseUrl
{
    _baseUrl = baseUrl;
    [YTKNetworkConfig sharedConfig].baseUrl = _baseUrl;
}

- (void)setSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    _sessionConfiguration = sessionConfiguration;
    [YTKNetworkConfig sharedConfig].sessionConfiguration = sessionConfiguration;
}

@end
