//
//  TDOrderAssitantCell.m
//  edX
//
//  Created by Elite Edu on 17/2/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDOrderAssitantCell.h"
#import <UIImageView+WebCache.h>

@interface TDOrderAssitantCell ()

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIImageView *headerImage;
@property (nonatomic,strong) UIImageView *statusImage;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UILabel *quetionLabel;
@property (nonatomic,strong) UIButton *orderButton;
@property (nonatomic,strong) UIButton *talkButton;

@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDOrderAssitantCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.toolModel = [[TDBaseToolModel alloc] init];
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

- (void)setModel:(TDTeacherModel *)model {
    _model = model;
    
    //设置头像
    NSString *url = [self.toolModel dealwithImageStr:model.avatar_url[@"large"]];
    [self.headerImage sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"default_big"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    self.nameLabel.text = model.name;
    self.quetionLabel.text = model.slogan;
    
    
    NSString *imageStr = @"offline";
    
    if ([model.realtime_status intValue] == 0) {
        [self remarkTalkButton:YES];
        imageStr = @"offline";
        
    } else if ([model.realtime_status intValue] == 1) { //离线(0)，空闲(1)，忙碌(2)
        [self remarkTalkButton:NO];
        imageStr = @"online";
    } else if ([model.realtime_status intValue] == 2) {
        [self remarkTalkButton:YES];
        imageStr = @"busy";
    }
    self.statusImage.image = [UIImage imageNamed:imageStr];
}

- (void)remarkTalkButton:(BOOL)isHidden {
    
    self.talkButton.hidden = isHidden;
    
    [self.talkButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.orderButton.mas_left).offset(-8);
        make.top.mas_equalTo(self.bgView.mas_top).offset(11);
        make.size.mas_equalTo(CGSizeMake(isHidden ? 0 : 68, 26));
    }];
}

#pragma mark - 按钮
- (void)orderButtonAction:(UIButton *)sender { //预约
    if (self.orderButtonHandle) {
        self.orderButtonHandle();
    }
}

- (void)talkButtonAction:(UIButton *)sender { //即时服务
    if (self.talkButtonHandle) {
        self.talkButtonHandle();
    }
}

- (void)tapHeaderImage { //头像
    if (self.headerHandle) {
        self.headerHandle();
    }
}


#pragma mark - UI
- (void)configView {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.headerImage = [[UIImageView alloc] init];
    self.headerImage.layer.masksToBounds = YES;
    self.headerImage.layer.cornerRadius = 28.0;
    self.headerImage.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    self.headerImage.layer.borderWidth = 0.5;
    [self.bgView addSubview:self.headerImage];
    
    self.statusImage = [[UIImageView alloc] init];
    [self.bgView addSubview:self.statusImage];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.nameLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.bgView addSubview:self.nameLabel];
    
    self.quetionLabel = [[UILabel alloc] init];
    self.quetionLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.quetionLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.quetionLabel.numberOfLines = 0;
    [self.bgView addSubview:self.quetionLabel];
    
    self.orderButton = [self setButtonWithTitle:NSLocalizedString(@"APPOINTMENT", nil) withColor:colorHexStr4];
    [self.orderButton addTarget:self action:@selector(orderButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.orderButton];
    
    self.talkButton = [self setButtonWithTitle:NSLocalizedString(@"INSTANT_SERVICE_BUTTON", nil) withColor:colorHexStr1];
    [self.talkButton addTarget:self action:@selector(talkButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.talkButton];
    
    self.headerImage.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeaderImage)];
    [self.headerImage addGestureRecognizer:gesture];
}

- (UIButton *)setButtonWithTitle:(NSString *)title withColor:(NSString *)colorStr {
    
    UIButton *customButton = [[UIButton alloc] init];
    customButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    customButton.backgroundColor = [UIColor colorWithHexString:colorStr];
    customButton.layer.cornerRadius = 13.0;
    customButton.showsTouchWhenHighlighted = YES;
    [customButton setTitle:title forState:UIControlStateNormal];
    [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return customButton;
}

- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(self);
    }];
    
    CGFloat width = [self sizeForButtonTitle:self.orderButton.titleLabel.text];
    
    [self.orderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.bgView.mas_right).offset(-8);
        make.top.mas_equalTo(self.bgView.mas_top).offset(11);
        make.height.mas_equalTo(26);
        make.width.mas_equalTo(width > 68 ? width : 68);
    }];
    
    [self.talkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.orderButton.mas_left).offset(-8);
        make.top.mas_equalTo(self.bgView.mas_top).offset(11);
        make.size.mas_equalTo(CGSizeMake(68, 26));
    }];
    
    [self.headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(self.bgView.mas_left).offset(11);
        make.size.mas_equalTo(CGSizeMake(58, 58));
    }];
    
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bgView.mas_top).offset(11);
        make.left.mas_equalTo(self.headerImage.mas_right).offset(8);
        make.right.mas_equalTo(self.talkButton.mas_left).offset(-3);
        make.height.mas_equalTo(26);
    }];
    
    [self.quetionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.nameLabel.mas_bottom).offset(0);
        make.left.mas_equalTo(self.headerImage.mas_right).offset(11);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-8);
        make.bottom.mas_equalTo(self.bgView.mas_bottom).offset(-8);
    }];
    
    [self.statusImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.headerImage.mas_right);
        make.bottom.mas_equalTo(self.headerImage.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(16, 16));
    }];
    
}

- (CGFloat)sizeForButtonTitle:(NSString *)title {
    return [self.toolModel widthForString:title font:14];
}

@end


