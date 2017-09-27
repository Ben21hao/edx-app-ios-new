//
//  TDBottomCouseView.m
//  edX
//
//  Created by Elite Edu on 16/12/12.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDBottomCouseView.h"
#import <UIImageView+WebCache.h>

@interface TDBottomCouseView ()

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIImageView *courseImage;
@property (nonatomic,strong) UILabel *titelLabel;
@property (nonatomic,strong) UILabel *moneyLabel;
@property (nonatomic,strong) UILabel *originalLabel;
@property (nonatomic,strong) UIButton *carButton;

@end

@implementation TDBottomCouseView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self config];
        [self setConstraint];
    }
    return self;
}

- (void)config {
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.courseImage = [[UIImageView alloc] init];
    self.courseImage.image = [UIImage imageNamed:@"course_backGroud"];
    [self.bgView addSubview:self.courseImage];
    
    self.bottomButton = [[UIButton alloc] init];
    [self.bgView addSubview:self.bottomButton];
    
    self.titelLabel = [[UILabel alloc] init];
    self.titelLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.titelLabel.font = [UIFont systemFontOfSize:14];
    self.titelLabel.text = NSLocalizedString(@"COURSE_TITLE", nil);
    [self.bgView addSubview:self.titelLabel];
    
    self.moneyLabel = [[UILabel alloc] init];
    self.moneyLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.moneyLabel.font = [UIFont systemFontOfSize:12];
    [self.bgView addSubview:self.moneyLabel];
    
    self.originalLabel = [[UILabel alloc] init];
    self.originalLabel.font = [UIFont systemFontOfSize:11];
    self.originalLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.bgView addSubview:self.originalLabel];
    
    self.carButton = [[UIButton alloc] init];
    [self.carButton setImage:[UIImage imageNamed:@"Page1"] forState:UIControlStateNormal];
    self.carButton.userInteractionEnabled = NO;
    [self.bgView addSubview:self.carButton];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    self.moneyLabel.attributedText = [baseTool setString:@"￥0.00" withFont:16  type:1];
    self.originalLabel.attributedText = [baseTool setString:@"￥0.00" withFont:12  type:2];
}

- (void)setConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.courseImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bgView.mas_top).offset(5); 
        make.left.mas_equalTo(self.bgView.mas_left).offset(5);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-5);
        make.height.mas_equalTo((TDWidth - 45) / 2 * 0.53);
    }];
    
    [self.bottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.mas_equalTo(self.bgView);
        make.top.mas_equalTo(self.courseImage.mas_bottom);
    }];
    
    [self.titelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.courseImage.mas_left).offset(0);
        make.top.mas_equalTo(self.courseImage.mas_bottom).offset(8);
        make.right.mas_equalTo(self.courseImage.mas_right).offset(0);
    }];
    
    [self.moneyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.titelLabel.mas_left).offset(0);
        make.top.mas_equalTo(self.titelLabel.mas_bottom).offset(5);
    }];
    
    [self.originalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.moneyLabel.mas_bottom).offset(0);
        make.left.mas_equalTo(self.moneyLabel.mas_right).offset(5);
    }];
    
    [self.carButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.courseImage.mas_right).offset(0);
        make.top.mas_equalTo(self.titelLabel.mas_bottom).offset(0);
    }];
}

#pragma mark - data
- (void)setCourseViewData:(ChooseCourseItem *)courseItem {
    if (courseItem) {
        self.titelLabel.text = courseItem.course_display_name;
        
        TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
        
        NSString *string1 = [NSString stringWithFormat:@"%@%@",ELITEU_URL,courseItem.course_pic];
        NSString* string2 = [baseTool dealwithImageStr:string1];
        [self.courseImage sd_setImageWithURL:[NSURL URLWithString:string2] placeholderImage:[UIImage imageNamed:@"Shape"]];
        
        self.moneyLabel.attributedText = [baseTool setString:[NSString stringWithFormat:@"￥%.2f",[courseItem.min_price floatValue]] withFont:16  type:1];
        self.originalLabel.attributedText = [baseTool setString:[NSString stringWithFormat:@"￥%.2f",[courseItem.suggest_price floatValue]] withFont:12  type:2];
    }
}


@end











