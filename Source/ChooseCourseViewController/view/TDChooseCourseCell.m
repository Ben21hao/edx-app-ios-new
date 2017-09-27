//
//  TDChooseCourseCell.m
//  edX
//
//  Created by Elite Edu on 16/12/10.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDChooseCourseCell.h"
#import <UIImageView+WebCache.h>
#import "TDBaseToolModel.h"

@interface TDChooseCourseCell ()

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIButton *selectButton;
@property (nonatomic,strong) UIImageView *courseImage;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *userNameLabel;
@property (nonatomic,strong) UILabel *moneyLabel;
@property (nonatomic,strong) UILabel *originalLabel;

@end

@implementation TDChooseCourseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self config];
        [self setConstraint];
    }
    return self;
}

- (void)config {
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.selectButton = [[UIButton alloc] init];
    [self.selectButton setImage:[UIImage imageNamed:@"Shape1"] forState:UIControlStateNormal];
    [self.selectButton setImage:[UIImage imageNamed:@"Shape"] forState:UIControlStateSelected];
    [self.selectButton addTarget:self action:@selector(selectButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.selectButton];
    
    self.courseImage = [[UIImageView alloc] init];
    self.courseImage.image = [UIImage imageNamed:@"course_backGroud"];
    self.courseImage.layer.masksToBounds = YES;
    self.courseImage.layer.cornerRadius = 4.0;
    [self.bgView addSubview:self.courseImage];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.bgView addSubview:self.titleLabel];
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.userNameLabel.font = [UIFont systemFontOfSize:12];
    [self.bgView addSubview:self.userNameLabel];
    
    self.moneyLabel = [[UILabel alloc] init];
    self.moneyLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.moneyLabel.font = [UIFont systemFontOfSize:16];
    [self.bgView addSubview:self.moneyLabel];
    
    self.originalLabel = [[UILabel alloc] init];
    self.originalLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.originalLabel.font = [UIFont systemFontOfSize:12];
    [self.bgView addSubview:self.originalLabel];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    self.moneyLabel.attributedText = [baseTool setString:@"￥0.00" withFont:16  type:1];
    self.originalLabel.attributedText = [baseTool setString:@"￥0.00" withFont:12  type:2];

}

- (void)setConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_left).offset(18);
        make.centerY.mas_equalTo(self.bgView);
        make.size.mas_equalTo(CGSizeMake(18, 18));
    }];
    
    [self.courseImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.selectButton.mas_right).offset(8);
        make.centerY.mas_equalTo(self.bgView);
        make.size.mas_equalTo(CGSizeMake(140, 78));
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.courseImage.mas_right).offset(8);
        make.top.mas_equalTo(self.courseImage.mas_top).offset(3);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-3);
    }];
    
    [self.userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.courseImage.mas_right).offset(8);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(3);
    }];
    
    [self.moneyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.courseImage.mas_right).offset(8);
        make.bottom.mas_equalTo(self.courseImage.mas_bottom).offset(-3);
    }];
    
    [self.originalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.moneyLabel.mas_right).offset(3);
        make.centerY.mas_equalTo(self.moneyLabel);
    }];
    
}


#pragma mark - 勾选
- (void)selectButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (self.selectButtonHandle) {
        self.selectButtonHandle(sender.selected);
    }
}

#pragma mark - 数据
- (void)setDataModel:(ChooseCourseItem *)model {
    if (model) {
        self.selectButton.selected = model.isSelected;
        
        TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
        NSString *string1 = [NSString stringWithFormat:@"%@%@",ELITEU_URL,model.course_pic];
        NSString* string2 = [baseTool dealwithImageStr:string1];
        [self.courseImage sd_setImageWithURL:[NSURL URLWithString:string2] placeholderImage:[UIImage imageNamed:@"course_backGroud"]];
        
        
        self.titleLabel.text = model.course_display_name;
        self.userNameLabel.text = model.professor_name;
        self.moneyLabel.attributedText = [baseTool setString:[NSString stringWithFormat:@"￥%.2f",[model.min_price floatValue]] withFont:16  type:1];
        self.originalLabel.attributedText = [baseTool setString:[NSString stringWithFormat:@"￥%.2f",[model.suggest_price floatValue]] withFont:12  type:2];
    }
}


@end
