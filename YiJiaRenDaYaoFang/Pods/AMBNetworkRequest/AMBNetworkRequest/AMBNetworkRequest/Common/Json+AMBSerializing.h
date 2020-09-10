//
//  Json+AMBSerializing.h
//  AMBHttpRequestFramework
//
//  Created by   马海林 on 2018/4/29.
//  Copyright © 2018年   马海林. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 将数组转换为json字符串类别
 */
@interface NSArray (AMBJSONSerializing)

- (NSString *)amb_JSONString;

@end

/**
 将字典转换为json字符串类别
 */
@interface NSDictionary (AMBJSONSerializing)

- (NSString *)amb_JSONString;

@end

/**
 将json字符串转为数组或者字典类别
 */
@interface NSString (AMBJSONSerializing)

- (id)amb_JSONObject;

@end
