//
//  TDDownloadCell.m
//  edX
//
//  Created by Ben on 2017/6/12.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDDownloadCell.h"
#import "edX-Swift.h"

@interface TDDownloadCell ()

@property (nonatomic,strong) UIView *bgView;

@end

@implementation TDDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setViewConstraint];
    }
    return self;
}

- (void)setViewConstraint {
    self.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.bgView = [[UIView alloc] init];
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.cornerRadius = 5;
    [self.contentView addSubview:self.bgView];
    
    self.infoView =  [[CourseCardView alloc] init];
    [self.bgView addSubview:self.infoView];
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView.mas_left).offset(8);
        make.right.mas_equalTo(self.contentView.mas_right).offset(-8);
        make.top.bottom.mas_equalTo(self.contentView);
    }];
    
    [self.infoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.bgView);
    }];
}

@end
