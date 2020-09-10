//
//  XXXTableViewCell.m
//  YiJiaRenDaYaoFang
//
//  Created by Ardura on 2020/9/10.
//  Copyright © 2020 TW. All rights reserved.
//

#import "XXXTableViewCell.h"

@implementation XXXTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        NSLog(@"添加到当前内容中来了");
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        UIViewController *viewController = window.rootViewController;
        
        if ([viewController isKindOfClass:[UITabBarController class]])
        {
            UIViewController *viewcontroller = ((UITabBarController *)viewController).selectedViewController;
            if ([viewcontroller isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)((UITabBarController *)viewcontroller).selectedViewController pushViewController:[UIViewController new] animated:YES];
            }else {
                [((UITabBarController *)viewcontroller).selectedViewController.navigationController pushViewController:viewController animated:YES];
            }
            
        }else if ([viewController isKindOfClass:[UINavigationController class]])
        {
            [(UINavigationController *)((UITabBarController *)viewController).selectedViewController pushViewController:[UIViewController new] animated:YES];
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
