//
//  otherOpenModel.h
//  LaoBaiXingYaoFang
//
//  Created by apple on 16/12/26.
//  Copyright © 2016年 TW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface otherOpenModel : NSObject

@property (nonatomic,copy)NSString *paramUrl;
@property (nonatomic,assign)BOOL isOpened;

- (id)initWithDictionary:(NSDictionary *)dic;

@end
