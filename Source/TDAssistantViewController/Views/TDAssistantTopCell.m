//
//  TDAssistantTopCell.m
//  edX
//
//  Created by Elite Edu on 17/2/13.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDAssistantTopCell.h"

@interface TDAssistantTopCell ()

@property (nonatomic,strong) UIView *bgView;

@end

@implementation TDAssistantTopCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

#pragma mark - UI
- (void)configView {
    self.bgView = [[UIView alloc] init];
    [self addSubview:self.bgView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.titleLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.bgView addSubview:self.titleLabel];
    
    self.videoButton = [[UIButton alloc] init];
    self.videoButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.videoButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.videoButton.layer.cornerRadius = 13.0;
    self.videoButton.showsTouchWhenHighlighted = YES;
    [self.videoButton setTitle:NSLocalizedString(@"VIDEO_REPLAY", nil) forState:UIControlStateNormal];
    [self.videoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.bgView addSubview:self.videoButton];

    
    self.cancelButton = [self setButtonConstraint:NSLocalizedString(@"CANCEL", nil) backGroundColor:colorHexStr1 titleColor:colorHexStr13];
    [self.bgView addSubview:self.cancelButton];
}

- (UIButton *)setButtonConstraint:(NSString *)title backGroundColor:(NSString *)color1 titleColor:(NSString *)color2 {
    
    UIButton *button   = [[UIButton alloc] init];
    button.backgroundColor = [UIColor colorWithHexString:color1];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:color2] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    button.layer.cornerRadius = 4.0;
    button.showsTouchWhenHighlighted = YES;
    return button;
}


- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(self.bgView.mas_left).offset(8);
    }];
    
    [self.videoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-8);
        make.size.mas_equalTo(CGSizeMake(88, 25));
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-8);
        make.size.mas_equalTo(CGSizeMake(68, 28));
    }];
}


@end
