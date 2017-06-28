//
//  TDCourseOutLineCell.m
//  edX
//
//  Created by Ben on 2017/6/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDCourseOutLineCell.h"

@interface TDCourseOutLineCell ()

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UILabel *titleLabel;

@end

@implementation TDCourseOutLineCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self config];
        [self setConstraint];
    }
    return self;
}

#pragma mark - data
- (void)setModel:(TDOutLineSectionsModel *)model {
    _model= model;
    
    self.titleLabel.text = model.display_name;
    if (model.units.count > 0) {
        [self setDataForOutLine:model.units];
    }
}

- (void)setDataForOutLine:(NSArray *)dataArray {
    
    if (dataArray.count > 0) {
        for (int i = 0; i < dataArray.count; i ++) {
            
            TDOutLineUnitsModel *unitsModel = dataArray[i];
            
            UILabel *subTitleLabel = [[UILabel alloc] init];
            subTitleLabel.font = [UIFont systemFontOfSize:12];
            subTitleLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
            subTitleLabel.text = unitsModel.display_name;
            [self.bgView addSubview:subTitleLabel];
            
            [subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(self.bgView.mas_top).offset(33 * (i + 1));
                make.left.mas_equalTo(self.bgView.mas_left).offset(39);
                make.height.mas_equalTo(33);
                make.right.mas_equalTo(self.bgView.mas_right).offset(-18);
            }];
        }
    }
}

#pragma mark - UI
- (void)config {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self addSubview:self.bgView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    self.titleLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.bgView addSubview:self.titleLabel];
}

- (void)setConstraint {
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_left).offset(20);
        make.top.mas_equalTo(self.bgView.mas_top).offset(0);
        make.height.mas_equalTo(33);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-38);
    }];
}

@end
