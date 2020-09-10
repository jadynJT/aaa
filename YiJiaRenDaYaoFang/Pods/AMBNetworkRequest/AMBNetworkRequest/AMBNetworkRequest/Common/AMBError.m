//
//  AMBError.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "AMBError.h"

@implementation AMBError

#pragma mark -
#pragma mark ==== 外部使用方法 ====
#pragma mark -
/**
 *  根据给定的错误类型和信息创建AMBError实例
 *
 *  @param errorType    错误类型
 *  @param errorMessage 错误描述信息
 *
 *  @return 返回AMBError实例
 */
+ (instancetype)errorWithType:(NSUInteger)errorType errorMessage:(NSString *)errorMessage
{
    return [[self alloc] initWithType:errorType errorMessage:errorMessage];
}

/**
 *  根据给定的错误类型和信息创建AMBError实例
 *
 *  @param errorType    错误类型
 *  @param errorMessage 错误描述信息
 *
 *  @return 返回AMBError实例
 */
- (instancetype)initWithType:(NSUInteger)errorType errorMessage:(NSString *)errorMessage
{
    NSString *errorString = errorMessage.length > 0 ? errorMessage : @"";
    return [self initWithDomain:kAMBErrorDomain code:errorType userInfo:@{NSLocalizedDescriptionKey : errorString}];
}

@end
