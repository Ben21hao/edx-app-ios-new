//
//  TDCouponCell.m
//  edX
//
//  Created by Ben on 2017/6/6.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDCouponCell.h"
#import "edX-Swift.h"

@interface TDCouponCell ()

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *subTitleLabel;
@property (nonatomic,strong) UILabel *typeLabel;
@property (nonatomic,strong) UILabel *timeLabel;
@property (nonatomic,strong) UIButton *detailButton;
@property (nonatomic,strong) UILabel *signLabel;
@property (nonatomic,strong) UILabel *detailLabel;

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIView *topView;
@property (nonatomic,strong) UIView *bottomView;
@property (nonatomic,strong) UIView *detailView;
@property (nonatomic,strong) UIView *blackView;

@end

@implementation TDCouponCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configCell];
        [self setCellConstraint];
    }
    return self;
}

//问号按钮
- (void)showDetailAction:(UIButton *)sender {
    self.detailButton.selected = !self.detailButton.selected;
    
    NSLog(@"按钮是否选中 ======== %d",self.detailButton.selected);
    if (self.showDetailHandle) {
        self.showDetailHandle(self.detailButton.selected);
    }
}

- (void)setCouponModel:(TDCouponModel *)couponModel {
    _couponModel = couponModel;
    [self showDataDetail:_couponModel];
}

- (void)showDataDetail:(TDCouponModel *)model {

    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    NSString *titleStr;
    NSString *subTitleStr;
    
    NSString *colorStr1;
    NSString *colorStr2;
    
    if ([model.coupon_type isEqualToString:@"满减券"]) {
        float money = [model.cutdown_price floatValue];
        titleStr = [NSString stringWithFormat:@"￥%.2f",money];
        subTitleStr = [Strings couponDeduction];
        
        colorStr1 = @"#F6BB42";
        colorStr2 = @"#FFFAED";
        
    } else if ([model.coupon_type isEqualToString:@"折扣券"]) {
        subTitleStr = [Strings couponDiscount];
        
        float rate = [model.discount_rate floatValue] * 10.0;
        titleStr = [NSString stringWithFormat:@"%.2lf折",rate];
        
        if (![subTitleStr isEqualToString:@"折扣券"]) { //英文状态时
            titleStr = [NSString stringWithFormat:@"%.0f%% OFF",(1 - [model.discount_rate floatValue]) * 100];
        }
        
        colorStr1 = colorHexStr1;
        colorStr2 = @"#EDFAFF";
        
    } else {
        float money = [model.cutdown_price floatValue];
        titleStr = [Strings couponForCourseWithCount:[NSString stringWithFormat:@"%.2lf",money]];
        subTitleStr = [Strings couponEnterprise];
        
        colorStr1 = @"#95CD5B";
        colorStr2 = @"#EBF6DF";
    }
    
    int status = [model.status intValue];
    
    if (status == 3) {
        colorStr1 = colorHexStr7;
        colorStr2 = colorHexStr5;
    }
    
    self.titleLabel.attributedText = [baseTool setDetailString:titleStr withFont:32 withColorStr:@"#ffffff"];
    self.subTitleLabel.text = model.coupon_name;
    self.typeLabel.text = subTitleStr;
    self.topView.backgroundColor = [UIColor colorWithHexString:colorStr1];
    self.bottomView.backgroundColor = [UIColor colorWithHexString:colorStr2];
    self.detailView.backgroundColor = [UIColor colorWithHexString:colorStr2];
    
    NSRange range = [model.coupon_begin_at rangeOfString:@"T"];
    self.timeLabel.text = [Strings couponPeriodWithStartdate:[model.coupon_begin_at substringToIndex:range.location] enddate:[model.coupon_end_at substringToIndex:range.location]];
    
    
    if (model.remark.length > 0) {
        
        if (status == 1) {
            self.detailButton.hidden = NO;
            self.detailLabel.text = model.remark;
        } else {
            self.detailButton.hidden = YES;
        }
    } else {
        self.detailButton.hidden = YES;
    }
    
    if (status == 1) {
        self.signLabel.hidden = YES;
        self.blackView.hidden = YES;
    } else if (status == 2) {
        self.signLabel.textColor = [UIColor whiteColor];
        self.signLabel.text = model.signStr;
    } else {
        self.blackView.hidden = YES;
        self.signLabel.text = model.signStr;
    }
    
    self.detailButton.selected = model.isSelected;
    self.detailView.hidden = !model.isSelected;
}


#pragma mark - UI
- (void)configCell {
    
    self.bgView =  [[UIView alloc] init];
    [self setViewConstraint:self.bgView];
    [self.contentView addSubview:self.bgView];

    self.topView = [[UIView alloc] init];
    [self.bgView addSubview:self.topView];
    
    self.bottomView = [[UIView alloc] init];
    [self.bgView addSubview:self.bottomView];
    
    self.detailView = [[UIView alloc] init];
    [self setViewConstraint:self.detailView];
    [self.contentView addSubview:self.detailView];
    
    self.titleLabel = [self setLabelColor:colorHexStr13 font:28];
    [self.topView addSubview:self.titleLabel];
    
    self.subTitleLabel = [self setLabelColor:colorHexStr13 font:12];
    [self.topView addSubview:self.subTitleLabel];
    
    self.detailButton = [[UIButton alloc] init];
    self.detailButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:28];
    self.detailButton.showsTouchWhenHighlighted = YES;
    [self.detailButton setTitle:@"\U0000f059" forState:UIControlStateNormal];
    [self.detailButton setTitleColor:[UIColor colorWithHexString:colorHexStr13] forState:UIControlStateNormal];
    [self.detailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateSelected];
    [self.detailButton addTarget:self action:@selector(showDetailAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.detailButton];
    
    self.typeLabel = [self setLabelColor:colorHexStr10 font:14];
    [self.bottomView addSubview:self.typeLabel];
    
    self.timeLabel = [self setLabelColor:colorHexStr8 font:12];
    [self.bottomView addSubview:self.timeLabel];
    
    self.blackView = [[UIView alloc] init];
    self.blackView.backgroundColor = [UIColor blackColor];
    self.blackView.alpha = 0.3;
    [self.bgView addSubview:self.blackView];
    
    self.signLabel = [self setLabelColor:@"#8B0000" font:28];
    self.signLabel.transform = CGAffineTransformMakeRotation(-0.6);
    [self.bgView addSubview:self.signLabel];
    
    self.detailLabel= [self setLabelColor:colorHexStr8 font:12];
    [self.detailView addSubview:self.detailLabel];
}

- (void)setCellConstraint {
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView.mas_left).offset(8);
        make.right.mas_equalTo(self.contentView.mas_right).offset(-8);
        make.top.mas_equalTo(self.contentView.mas_top).offset(8);
        make.height.mas_equalTo(148);
    }];
    
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.bgView);
        make.height.mas_equalTo(80);
    }];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.bgView);
        make.top.mas_equalTo(self.topView.mas_bottom);
        make.height.mas_equalTo(68);
    }];
    
    [self.detailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView.mas_left).offset(8);
        make.right.mas_equalTo(self.contentView.mas_right).offset(-8);
        make.bottom.mas_equalTo(self.contentView.mas_bottom).offset(-8);
        make.top.mas_equalTo(self.bgView.mas_bottom).offset(3);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.topView);
        make.centerY.mas_equalTo(self.topView.mas_centerY).offset(-8);
    }];
    
    [self.subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.topView);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(3);
    }];
    
    [self.typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bottomView);
        make.bottom.mas_equalTo(self.bottomView.mas_centerY).offset(-3);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bottomView);
        make.top.mas_equalTo(self.bottomView.mas_centerY).offset(3);
    }];
    
    [self.detailButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.topView.mas_top).offset(8);
        make.right.mas_equalTo(self.topView.mas_right).offset(-8);
        make.size.mas_equalTo(CGSizeMake(28, 28));
    }];
    
    [self.blackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.bgView);
    }];
    
    [self.signLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_right).offset(-88);
        make.centerY.mas_equalTo(self.topView.mas_bottom);
    }];
    
    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.detailView.mas_centerY);
        make.left.right.mas_equalTo(self.detailView);
    }];

}

- (UILabel *)setLabelColor:(NSString *)colorStr font:(NSInteger)num {
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor colorWithHexString:colorStr];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"OpenSans" size:num];
    return label;
}

- (void)setViewConstraint:(UIView *)view {
    view.layer.cornerRadius = 10;
    view.clipsToBounds = YES;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [[UIColor colorWithHexString:colorHexStr7] CGColor];
}


@end
