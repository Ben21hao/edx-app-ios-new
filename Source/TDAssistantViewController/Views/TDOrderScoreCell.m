//
//  TDOrderScoreCell.m
//  edX
//
//  Created by Elite Edu on 17/3/2.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDOrderScoreCell.h"
#import "TDBaseView.h"
#import "TDBaseToolModel.h"
#import "TDAssistantCommentTagModel.h"

@interface TDOrderScoreCell ()

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) TDBaseView *topView;
@property (nonatomic,strong) UIView *starView;
@property (nonatomic,strong) UIImageView *lineImageView;
@property (nonatomic,strong) UIView *tagView;

@property (nonatomic,strong) UILabel *scoreLabel;

@property (nonatomic,strong) NSMutableArray *startButtonArray;
@property (nonatomic,strong) NSMutableArray *tagButtonArray;

@end

@implementation TDOrderScoreCell

- (NSMutableArray *)startButtonArray {
    if (!_startButtonArray) {
        _startButtonArray = [[NSMutableArray alloc] init];
    }
    return _startButtonArray;
}

- (NSMutableArray *)tagButtonArray {
    if (!_tagButtonArray) {
        _tagButtonArray = [[NSMutableArray alloc] init];
    }
    return _tagButtonArray;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.baseTool = [[TDBaseToolModel alloc] init];
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

- (void)setScoreStr:(NSString *)scoreStr {
    _scoreStr = scoreStr;
    [self setStarViewConstraint];
}

- (void)setStarViewConstraint {
    for (int i = 0; i < 5; i ++) {
        UIButton *button = [[UIButton alloc] init];
        button.tag = i;
        button.selected = i < [self.scoreStr intValue] ? YES : NO;
        [button setImage:[UIImage imageNamed:@"star11"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"star1"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(starButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.starView addSubview:button];
        
        [self.startButtonArray addObject:button];
        
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.starView.mas_left).offset(i * 28);
            make.centerY.mas_equalTo(self.starView.mas_centerY);
            make.size.mas_equalTo(CGSizeMake(23, 23));
        }];
    }
}

- (void)starButtonAction:(UIButton *)sender {
    for (int i = 0 ; i < self.startButtonArray.count; i ++) {
        UIButton *button = self.startButtonArray[i];
        if (i <= sender.tag) {
            button.selected = YES;
        } else {
            button.selected = NO;
        }
    }
    
    switch (sender.tag) {
        case 0:
            self.scoreLabel.text = NSLocalizedString(@"NOT_SATISFIED", nil);
            break;
        case 1:
            self.scoreLabel.text = NSLocalizedString(@"NOT_SATISFIED", nil);
            break;
        case 2:
            self.scoreLabel.text = NSLocalizedString(@"COMMOND_SATISFIED", nil);
            break;
        case 3:
            self.scoreLabel.text = NSLocalizedString(@"COMMOND_SATISFIED", nil);
            break;
        case 4:
            self.scoreLabel.text = NSLocalizedString(@"VERY_SATISFIED", nil);
            break;
            
        default:
            break;
    }
    if (self.startButtonHandle) {
        self.startButtonHandle(sender.tag);
    }
}

- (void)setTagArray:(NSArray *)tagArray {
    _tagArray = tagArray;
    [self setTagViewConstaint];
}

- (void)setTagViewConstaint {
    for (int i = 0; i < self.tagArray.count; i ++) {
        TDAssistantCommentTagModel *tagModel = self.tagArray[i];
        NSString *title = tagModel.tag_name;
        
        UIButton *button = [[UIButton alloc] init];
        button.tag = i;
        button.selected = tagModel.isSelected;
        button.backgroundColor = [UIColor colorWithHexString:tagModel.isSelected ? colorHexStr2 : colorHexStr5];
        button.layer.cornerRadius = 11.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
        button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithHexString:colorHexStr13] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(tagButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.tagView addSubview:button];
        
        int low = i / 3;
        int width = (TDWidth - 58) / 3;
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.tagView.mas_left).offset((i % 3) * (width + 11));
            make.top.mas_equalTo(self.tagView.mas_top).offset(31 * low);
            make.size.mas_equalTo(CGSizeMake(width , 25));
        }];
    }
}

- (void)tagButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        sender.backgroundColor = [UIColor colorWithHexString:colorHexStr2];
        sender.layer.borderColor = [UIColor colorWithHexString:colorHexStr5].CGColor;
    } else {
        sender.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        sender.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    }
    if (self.tagButtonHandle) {
        self.tagButtonHandle(sender.tag,sender.selected);
    }
}

#pragma mark - UI
- (void)configView {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.topView = [[TDBaseView alloc] initWithTitle:NSLocalizedString(@"STATISFACTION_LEVEL", nil)];
    [self.bgView addSubview:self.topView];
    
    self.starView = [[UIView alloc] init];
    [self.bgView addSubview:self.starView];
    
    self.scoreLabel = [[UILabel alloc] init];
    self.scoreLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.scoreLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.bgView addSubview:self.scoreLabel];
    
    self.lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 98, TDWidth, 2)];
    self.lineImageView.image = [self.baseTool drawLineByImageView:self.lineImageView withColor:colorHexStr8];
    [self.bgView addSubview:self.lineImageView];
    
    self.tagView = [[UIView alloc] init];
    [self.bgView addSubview:self.tagView];
  
}

- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.bgView.mas_top).offset(8);
        make.left.right.mas_equalTo(self.bgView);
        make.height.mas_equalTo(39);
    }];
    
    [self.starView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.topView.mas_bottom).offset(0);
        make.left.mas_equalTo(self.bgView).offset(11);
        make.size.mas_equalTo(CGSizeMake(141, 48));
    }];
    
    [self.scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.starView.mas_centerY).offset(1);
        make.left.mas_equalTo(self.starView.mas_right).offset(8);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.lineImageView.mas_bottom).offset(18);
        make.left.mas_equalTo(self.bgView.mas_left).offset(11);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-11);
        make.bottom.mas_equalTo(self.bgView);
    }];
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
