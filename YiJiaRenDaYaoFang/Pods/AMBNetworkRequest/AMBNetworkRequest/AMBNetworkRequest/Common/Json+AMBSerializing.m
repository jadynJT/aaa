//
//  Json+AMBSerializing.m
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import "Json+AMBSerializing.h"

CF_INLINE NSString *parseObject2JsonString(id object);
CF_INLINE id parseJsonString2Object(NSString *jsonString);

/**
 将object转为json字符串

 @param object 要转化的object
 @return 返回json字符串
 */
CF_INLINE NSString *parseObject2JsonString(id object)
{
    if (!object)
    {
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    return error ? nil : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 将json字符串转为object

 @param jsonString 要转化的json字符串
 @return 返回object
 */
CF_INLINE id parseJsonString2Object(NSString *jsonString)
{
    if (!jsonString || jsonString.length == 0)
    {
        return nil;
    }
    
    NSError *error = nil;
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return error ? nil : obj;
}

@implementation NSArray (AMBJSONSerializing)

- (NSString *)amb_JSONString
{
    return parseObject2JsonString(self);
}

@end

@implementation NSDictionary (AMBJSONSerializing)

- (NSString *)amb_JSONString
{
    return parseObject2JsonString(self);
}

@end

@implementation NSString (AMBJSONSerializing)

- (id)amb_JSONObject
{
    return parseJsonString2Object(self);
}

@end

