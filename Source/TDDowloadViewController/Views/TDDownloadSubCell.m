//
//  TDDownloadSubCell.m
//  edX
//
//  Created by Ben on 2017/6/13.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDDownloadSubCell.h"
#import "edX-Swift.h"

@interface TDDownloadSubCell ()

@property (nonatomic,strong) UIView *bgView;

@end

@implementation TDDownloadSubCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configViewCell];
        [self setViewConstraint];
    }
    return self;
}

- (void)configViewCell {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.contentView addSubview:self.bgView];
    
    self.img_VideoWatchState = [[UIImageView alloc] init];
    [self.bgView addSubview:self.img_VideoWatchState];
    
    self.lbl_Title = [self setLabelStyle:14 color:colorHexStr10];
    [self.bgView addSubview:self.lbl_Title];
    
    self.lbl_Time = [self setLabelStyle:12 color:colorHexStr8];
    [self.bgView addSubview:self.lbl_Time];
    
    self.lbl_Size = [self setLabelStyle:12 color:colorHexStr8];
    [self.bgView addSubview:self.lbl_Size];
    
    self.btn_CheckboxDelete = [[OEXCheckBox alloc] initWithFrame:CGRectMake(0, 30, 38, 38)];
    [self.bgView addSubview:self.btn_CheckboxDelete];
}

- (UILabel *)setLabelStyle:(NSInteger)font color:(NSString *)hexStr {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:font];
    label.textColor = [UIColor colorWithHexString:hexStr];
    return label;
}

- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.contentView);
    }];
    
    [self.img_VideoWatchState mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.left.mas_equalTo(self.bgView.mas_left).offset(15);
        make.size.mas_equalTo(CGSizeMake(15, 15));
    }];
    
    [self.lbl_Title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.img_VideoWatchState.mas_right).offset(22);
        make.bottom.mas_equalTo(self.bgView.mas_centerY).offset(-3);
    }];
    
    [self.lbl_Time mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.lbl_Title.mas_left);
        make.top.mas_equalTo(self.bgView.mas_centerY).offset(3);
        make.width.mas_equalTo(47);
    }];
    
    [self.lbl_Size mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.lbl_Time.mas_right).offset(3);
        make.top.mas_equalTo(self.lbl_Time.mas_top);
    }];
    
    [self.btn_CheckboxDelete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.bgView.mas_right).offset(-8);
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(38, 38));
    }];
}

@end


