//
//  TDVideoShareCell.m
//  edX
//
//  Created by Elite Edu on 17/3/2.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDVideoShareCell.h"

@interface TDVideoShareCell ()

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UIButton *allowButton;
@property (nonatomic,strong) UIButton *notAllowButton;

@end

@implementation TDVideoShareCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

#pragma mark - 按钮
- (void)allowButtonAction:(UIButton *)sender { //允许
    [self selectHandle:0];
}

- (void)notAllowButtonAction:(UIButton *)sender { //不允许
    [self selectHandle:1];
}

- (void)selectHandle:(NSInteger)type {
    self.allowButton.selected = type == 0 ? YES : NO;
    self.notAllowButton.selected = type == 0 ? NO : YES;
    
    if (self.shareButtonHandle) {
        self.shareButtonHandle(type);
    }
}

#pragma mark - UI
- (void)configView {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.titleLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.titleLabel.text = @"视频分享";
    [self.bgView addSubview:self.titleLabel];
    
    self.allowButton = [self setButton:NSLocalizedString(@"ALLOW", nil)];
    self.allowButton.tag = 0;
    self.allowButton.selected = YES;
    [self.allowButton addTarget:self action:@selector(allowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.allowButton];
    
    self.notAllowButton = [self setButton:NSLocalizedString(@"DO_NOT_ALLOW", nil)];
    self.notAllowButton.tag = 1;
    [self.notAllowButton addTarget:self action:@selector(notAllowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.notAllowButton];
}
- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_left).offset(11);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.allowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titleLabel.mas_right).offset(18);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
    
    [self.notAllowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.allowButton.mas_right).offset(18);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
    }];
}

- (UIButton *)setButton:(NSString *)title {
    UIButton *button = [[UIButton alloc] init];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 2, 0, -2);
    button.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 2);
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:colorHexStr10] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"selectedNo"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"selected"] forState:UIControlStateSelected];
    return button;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
