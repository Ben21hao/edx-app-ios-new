//
//  UserCouponTableViewCell.m
//  edX
//
//  Created by Elite Edu on 16/8/29.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "UserCouponTableViewCell.h"
#import "UserCouponItem.h"
#import "edX-Swift.h"

@interface UserCouponTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *contV;

@end

@implementation UserCouponTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    //文本倾斜
    _usedL.transform = CGAffineTransformMakeRotation(-0.6);
    _outTime.transform = CGAffineTransformMakeRotation(-0.6);
    
    self.detailButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    self.detailButton.showsTouchWhenHighlighted = YES;
    [self.detailButton setTitle:@"\U0000f059" forState:UIControlStateNormal];
    [self.detailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateSelected];
    [self.detailButton addTarget:self action:@selector(showDetailAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self setViewConstraint:self.contV];
    [self setViewConstraint:self.detailView];
    self.detailLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.waterV.backgroundColor = [UIColor colorWithHexString:colorHexStr10];
    self.waterV.alpha = 0.4;
}

- (void)setViewConstraint:(UIView *)view {
    view.layer.cornerRadius = 10;
    view.clipsToBounds = YES;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[UIColor colorWithHexString:colorHexStr7] CGColor];
}

- (void)showDetailAction:(UIButton *)sender {
    self.detailButton.selected = !self.detailButton.selected;
    
    NSLog(@"按钮是否选中 ======== %d",self.detailButton.selected);
    if (self.showDetailHandle) {
        self.showDetailHandle(self.detailButton.selected);
    }
}

- (void)setUserCouponItem:(UserCouponItem *)UserCouponItem{
    _UserCouponItem = UserCouponItem;
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    NSString *titleStr;
    NSString *subTitleStr;
    
    if ([UserCouponItem.coupon_type isEqualToString:@"满减券"]) {
        float money = [_UserCouponItem.cutdown_price floatValue];
        titleStr = [NSString stringWithFormat:@"￥%.2f",money];
        subTitleStr = [Strings couponDeduction];
        
    } else if ([UserCouponItem.coupon_type isEqualToString:@"折扣券"]) {
        subTitleStr = [Strings couponDiscount];
        
        float rate = [_UserCouponItem.discount_rate floatValue] * 10.0;
        titleStr = [NSString stringWithFormat:@"%.2lf折",rate];
        
        if (![subTitleStr isEqualToString:@"折扣券"]) {
            titleStr = [NSString stringWithFormat:@"%.0f%% OFF",(1 - [_UserCouponItem.discount_rate floatValue]) * 100];
        }
        
    } else {
        float money = [_UserCouponItem.cutdown_price floatValue];
        titleStr = [Strings couponForCourseWithCount:[NSString stringWithFormat:@"%.2lf",money]];
        subTitleStr = [Strings couponEnterprise];
    }
    
    _firstL.attributedText = [baseTool setDetailString:titleStr withFont:32 withColorStr:@"#ffffff"];
    _secondL.text = _UserCouponItem.coupon_name;
    _thirdL.text = subTitleStr;
    
    if (self.UserCouponItem.remark.length > 0) {
        
        if (self.UserCouponItem.status == 1) {
            self.detailButton.hidden = NO;
            self.detailLabel.text = self.UserCouponItem.remark;
        } else {
            self.detailButton.hidden = YES;
        }
    } else {
        self.detailButton.hidden = YES;
    }
    
    self.detailButton.selected = self.UserCouponItem.isSelected;
    
    NSRange range = [self.UserCouponItem.coupon_begin_at rangeOfString:@"T"];
    self.fourthL.text = [Strings couponPeriodWithStartdate:[_UserCouponItem.coupon_begin_at substringToIndex:range.location] enddate:[_UserCouponItem.coupon_end_at substringToIndex:range.location]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


@end
