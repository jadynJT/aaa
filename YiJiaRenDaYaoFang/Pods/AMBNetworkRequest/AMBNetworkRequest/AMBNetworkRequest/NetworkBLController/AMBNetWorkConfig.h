//
//  AMBNetWorkConfig.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/5/2.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 接口请求公用配置类
 */
@interface AMBNetWorkConfig : NSObject

/**
 基础url，默认为空
 */
@property (nonatomic, copy) NSString *baseUrl;

/**
 版本号，默认为空
 */
@property (nonatomic, copy) NSString *version;

/**
 NSURLSessionConfiguration实例，默认为空
 */
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

/**
 接口请求所需的公共头部，默认为空(各个接口相同的请求头，请在这里设置)
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *globalRequestHeaderFieldValueDictionary;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 创建AMBNetWorkConfig单例
 
 @return 返回AMBNetWorkConfig实例
 */
+ (AMBNetWorkConfig *)sharedNetWorkConfig;

@end
