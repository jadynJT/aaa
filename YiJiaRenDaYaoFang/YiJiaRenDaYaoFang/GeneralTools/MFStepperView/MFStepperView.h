//
//  MFStepperView.h
//  JuShanTangYaoDian
//
//  Created by apple on 17/1/3.
//  Copyright © 2017年 TW. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXHRulerScrollView.h"

@class MFStepperView;

@interface MFStepperView : UIControl

@property (nonatomic, strong, readonly)UITextField *showTF;

- (instancetype)initwithMin:(float)min Max:(float)max;

@end
