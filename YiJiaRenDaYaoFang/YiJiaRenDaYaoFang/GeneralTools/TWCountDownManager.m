//
//  CountDownManager.m
//  CellCountDown
//
//  Created by herobin on 16/9/11.
//  Copyright © 2016年 herobin. All rights reserved.
//

#import "TWCountDownManager.h"

@interface TWCountDownManager ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TWCountDownManager

+ (instancetype)manager {
    static TWCountDownManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TWCountDownManager alloc] init];
    });
    return manager;
}

- (void)start {
    // 启动定时器
    [self timer];
}

- (void)invalidate{
    // 取消定时器
    [_timer invalidate];
    _timer = nil;
}

- (void)reload {
    // 刷新只要让时间差为0即可
    _timeInterval = 0;
}

- (void)timerAction {
    // 时间差+1
    self.timeInterval ++;
    // 发出通知--可以将时间差传递出去,或者直接通知类属性取
    [[NSNotificationCenter defaultCenter] postNotificationName:kCountDownNotification object:nil userInfo:@{@"TimeInterval" : @(self.timeInterval)}];
}

- (NSTimer *)timer {
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

@end
