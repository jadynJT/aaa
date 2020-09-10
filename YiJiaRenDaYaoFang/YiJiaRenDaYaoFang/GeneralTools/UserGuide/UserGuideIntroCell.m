//
//  LaunchScreenIntroCollectionViewCell.m
//  yxt_kinder
//
//  Created by libz on 17/1/3.
//  Copyright © 2017年 Nenglong. All rights reserved.
//

#import "UserGuideIntroCell.h"
#import "Masonry.h"

@interface UserGuideIntroCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation UserGuideIntroCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.dismissButton];
        self.backgroundColor = [UIColor clearColor];
        
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.equalTo(@0);
//            make.centerX.equalTo(self.contentView.mas_centerX);
//            make.centerY.equalTo(self.contentView.mas_centerY).offset(-20);
//            make.width.equalTo(self.contentView).multipliedBy(0.8);
//            make.height.equalTo(self.imageView.mas_width).multipliedBy(1.34);
        }];
        
        [self.dismissButton mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.centerX.equalTo(self.contentView.mas_centerX);
            make.left.right.equalTo(@0);
            make.height.equalTo(@(self.contentView.frame.size.height*0.16));
            make.bottom.equalTo(self.contentView).offset(0);
        }];
    }
    return self;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.layer.masksToBounds = YES;
    }
    return _imageView;
}

- (void)setImageName:(NSString *)imageName {
    if (_imageName != imageName) {
        _imageName = [imageName copy];
        
        if ([Utility isIPhone5] || [Utility isIPhone6]) {
            _imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-568h",imageName]];
        }else
        {
            _imageView.image = [UIImage imageNamed:imageName];
        }
    }
}

- (UIButton *)dismissButton {
    if (!_dismissButton) {
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _dismissButton.backgroundColor = [UIColor redColor];
//        [_dismissButton setImage:[UIImage imageNamed:@"intro_entry_app_btn_image_normal"] forState:UIControlStateNormal];
//        [_dismissButton setImage:[UIImage imageNamed:@"intro_entry_app_btn_image_highlight"] forState:UIControlStateHighlighted];
        [_dismissButton addTarget:self action:@selector(dismissButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}

- (void)dismissButtonTapped:(id)sender {
    if (self.dismissButtonAction) {
        self.dismissButtonAction();
    }
}

@end
