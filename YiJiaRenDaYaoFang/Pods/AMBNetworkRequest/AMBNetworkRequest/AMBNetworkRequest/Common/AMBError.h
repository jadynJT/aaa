//
//  AMBError.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kAMBErrorDomain = @"com.amb";

/**
 *  错误类型
 */
typedef NS_ENUM(NSUInteger, AMBErrorType)
{
    /**
     *  未知错误
     */
    AMBErrorTypeTypeUndefinded,
    
    /**
     *  获取数据成功，但code并不代表成功
     */
    AMBErrorTypeCodeError,
    
    /**
     *  返回数据格式错误
     */
    AMBErrorTypeReturnDataStyleError,
    
    /**
     *  网络错误
     */
    AMBErrorTypeNetworkUnreachable
};

/**
 *  封装错误类型
 */
@interface AMBError : NSError

/**
 *  根据给定的错误类型和信息创建AMBError实例
 *
 *  @param errorType    错误类型
 *  @param errorMessage 错误描述信息
 *
 *  @return 返回AMBError实例
 */
+ (instancetype)errorWithType:(NSUInteger)errorType errorMessage:(NSString *)errorMessage;

/**
 *  根据给定的错误类型和信息创建AMBError实例
 *
 *  @param errorType    错误类型
 *  @param errorMessage 错误描述信息
 *
 *  @return 返回AMBError实例
 */
- (instancetype)initWithType:(NSUInteger)errorType errorMessage:(NSString *)errorMessage;

@end
