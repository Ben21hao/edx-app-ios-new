//
//  TDTeacherCommentCell.m
//  edX
//
//  Created by Elite Edu on 17/3/7.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeacherCommentCell.h"

#import "TDTeacherTagModel.h"

#import <UIImageView+WebCache.h>
#import <MJExtension/MJExtension.h>

#define StarView_Width 128
#define Detail_LeftWidth 13

@interface TDTeacherCommentCell ()

@property (nonatomic,strong) UILabel *timeLabel;//时间
@property (nonatomic,strong) UIButton *praiseButton;//点赞
@property (nonatomic,strong) UILabel *numLabel;//点赞数量
@property (nonatomic,strong) UIButton *moreButton;//显示更多
@property (nonatomic,strong) UIView *bgView;//背景
@property (nonatomic,strong) UIImageView *headerImage;//头像
@property (nonatomic,strong) UIView *starView;//星星
@property (nonatomic,strong) UILabel *userName;//用户名
@property (nonatomic,strong) UILabel *commentLabel;//评论
@property (nonatomic,strong) UIView *tagView;//标签

@property (nonatomic,assign) float maxCommentLabelHeight;

@end

@implementation TDTeacherCommentCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configCell];
        [self setCellConstraint];
    }
    return self;
}

#pragma mark - 数据
- (void)setDetailItem:(TDTeacherCommentModel *)detailItem {
    _detailItem = detailItem;
    
    [self.headerImage sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",ELITEU_URL,_detailItem.avatar_url]] placeholderImage:[UIImage imageNamed:@"default_big"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    [self starviewSetData:_detailItem.score];
    
    self.userName.text = _detailItem.nick_name;
    self.commentLabel.text = _detailItem.content;
    self.timeLabel.text = _detailItem.create_at;
    self.numLabel.text = _detailItem.praise_num;
    self.praiseButton.selected = _detailItem.is_praise;
    
    [self tagviewSetData:_detailItem.comment_tags];
    
    CGSize size = [_detailItem.content boundingRectWithSize:CGSizeMake(TDWidth - 95, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14]} context:nil].size;
    if (size.height > self.maxCommentLabelHeight) {
        
        _detailItem.showMoreButton = YES;
        
        self.moreButton.hidden = NO;
        [self.moreButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.commentLabel.mas_bottom).offset(8);
            make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
            make.height.mas_equalTo(19);
        }];
        [self.tagView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
            make.top.mas_equalTo(self.moreButton.mas_bottom).offset(8);
            make.bottom.mas_equalTo(self.timeLabel.mas_top).offset(-8);
        }];
    }
    
    self.moreButton.selected = _detailItem.click_Open;
    if (_detailItem.click_Open) {
        [self.commentLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.userName.mas_bottom).offset(8);
            make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
            make.right.mas_equalTo(self.bgView.mas_right).offset(-18);
        }];
    }
}

- (void)starviewSetData:(NSString *)scoreStr {
    
    for (int i = 0; i < 5; i ++) {
        
        UIButton *starBttuon = [[UIButton alloc] init];
        
        if (i > [scoreStr intValue]) {
            [starBttuon setImage:[UIImage imageNamed:@"star11"] forState:UIControlStateNormal];
        } else {
            [starBttuon setImage:[UIImage imageNamed:@"star1"] forState:UIControlStateNormal];
        }
        [self.starView addSubview:starBttuon];
        [starBttuon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.starView.mas_left).offset(19 * i);
            make.centerY.mas_equalTo(self.starView);
            make.size.mas_equalTo(CGSizeMake(16, 16));
        }];
    }
}

- (void)tagviewSetData:(NSArray *)tagArray {//标签
    /*
     标签 - 一行三个标签
     */
    int tagWidth = (TDWidth - 79) / 3;
    for (int i = 0; i < tagArray.count; i ++) {
        
        int rang = i % 3;
        
        UIButton *tagButton = [[UIButton alloc] init];
        tagButton.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        [tagButton setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        tagButton.layer.cornerRadius = 11.0;
        tagButton.layer.borderColor = [UIColor colorWithHexString:colorHexStr8].CGColor;
        tagButton.layer.borderWidth = 0.5;
        
        TDTeacherTagModel *topItem = [TDTeacherTagModel mj_objectWithKeyValues:tagArray[i]];
        [tagButton setTitle:[NSString stringWithFormat:@"%@",topItem.name] forState:UIControlStateNormal];
        [self.tagView addSubview:tagButton];
        
        [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.tagView.mas_left).offset(rang * (tagWidth - 3));
            make.top.mas_equalTo(self.tagView.mas_top).offset(i / 3 * (23 + 3));
            make.size.mas_equalTo(CGSizeMake(tagWidth - 6, 23));
        }];
    }
}

#pragma mark - 点赞praise或取消点赞cancel_praise
- (void)praiseButtonAction:(UIButton *)sender {
    if (self.username.length == 0) {
        [[UIApplication sharedApplication].keyWindow.rootViewController.view makeToast:NSLocalizedString(@"LOGIN_AND_COMMENT", nil) duration:1.08 position:CSToastPositionCenter];
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:self.detailItem.id forKey:@"comment_id"];
    [dic setValue:self.username forKey:@"username"];
    
    NSString *path = sender.selected ? @"/api/mobile/enterprise/v0.5/assistant/comments/cancel_praise/" :  @"/api/mobile/enterprise/v0.5/assistant/comments/praise/";
    NSString *url = [NSString stringWithFormat:@"%@%@",ELITEU_URL,path];
    
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *dict = responseObject;
        NSString *code = dict[@"code"];
        if ([code intValue] == 200) {
            NSString *praiseNum = self.detailItem.praise_num;
            if (sender.selected) {
                self.detailItem.praise_num = [NSString stringWithFormat:@"%d",[praiseNum intValue] - 1];
                
            } else {
                self.detailItem.praise_num = [NSString stringWithFormat:@"%d",[praiseNum intValue] + 1];
            }
            self.numLabel.text = self.detailItem.praise_num;
            sender.selected = !sender.selected;
            self.detailItem.is_praise = sender.selected;
            
            if (self.clickPraiseButton) {
                self.clickPraiseButton(self.detailItem.praise_num,self.detailItem.is_praise);;
            }
            
        }else if ([code intValue] == 312){
            [[UIApplication sharedApplication].keyWindow.rootViewController.view makeToast:NSLocalizedString(@"AREADY_COMMENT", nil) duration:1.08 position:CSToastPositionCenter];
        } else {
            NSLog(@" 点赞出错 ==  %@",code);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"errorCode---%ld---",(long)error.code);
    }];
}

#pragma mark - UI
- (void)configCell {
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.headerImage = [[UIImageView alloc] init];
    self.headerImage.layer.masksToBounds = YES;
    self.headerImage.layer.cornerRadius = 24.0;
    self.headerImage.layer.borderWidth = 1.0;
    self.headerImage.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    [self.bgView addSubview:self.headerImage];
    
    self.starView = [[UIView alloc] init];
    [self.bgView addSubview:self.starView];
    
    self.userName = [[UILabel alloc] init];
    self.userName.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.userName.textColor = [UIColor colorWithHexString:colorHexStr9];
    [self.bgView addSubview:self.userName];
    
    self.commentLabel = [[UILabel alloc] init];
    self.commentLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.commentLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.commentLabel.numberOfLines = 0;
    if (self.maxCommentLabelHeight == 0) {
        self.maxCommentLabelHeight = self.commentLabel.font.lineHeight * 4;
    }
    [self.bgView addSubview:self.commentLabel];
    
    self.moreButton = [[UIButton alloc] init];
    self.moreButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    [self.moreButton setTitle:NSLocalizedString(@"SHOW_MORE", nil) forState:UIControlStateNormal];
    [self.moreButton setTitle:NSLocalizedString(@"PACK_UP", nil) forState:UIControlStateSelected];
    [self.moreButton setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.moreButton];
    
    self.tagView = [[UIView alloc] init];
    [self.bgView addSubview:self.tagView];
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.timeLabel.textColor = [UIColor colorWithHexString:colorHexStr7];
    [self.bgView addSubview:self.timeLabel];
    
    self.numLabel = [[UILabel alloc] init];
    self.numLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.numLabel.textColor = [UIColor colorWithHexString:colorHexStr7];
    [self.bgView addSubview:self.numLabel];
    
    self.praiseButton = [[UIButton alloc] init];
    [self.praiseButton setImage:[UIImage imageNamed:@"CombinedShape2"] forState:UIControlStateNormal];
    [self.praiseButton setImage:[UIImage imageNamed:@"CombinedShape1"] forState:UIControlStateSelected];
    [self.praiseButton addTarget:self action:@selector(praiseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.praiseButton.imageEdgeInsets = UIEdgeInsetsMake(5, 15, 5, 5);
    [self.bgView addSubview:self.praiseButton];
}

- (void)setCellConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_left).offset(Detail_LeftWidth);
        make.top.mas_equalTo(self.bgView.mas_top).offset(8);
        make.size.mas_equalTo(CGSizeMake(48, 48));
    }];
    
    [self.starView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.top.mas_equalTo(self.headerImage.mas_top);
        make.size.mas_equalTo(CGSizeMake(StarView_Width, 29));
    }];
    
    [self.userName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.top.mas_equalTo(self.starView.mas_bottom).offset(8);
    }];
    
    [self.commentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.userName.mas_bottom).offset(8);
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-18);
        make.height.mas_lessThanOrEqualTo(self.maxCommentLabelHeight);
    }];
    
    self.moreButton.hidden = YES;
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.commentLabel.mas_bottom).offset(8);
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.height.mas_equalTo(0);
    }];
    
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.bottom.mas_equalTo(self.bgView.mas_bottom).offset(-5);
    }];
    
    [self.numLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.bgView.mas_right).offset(-15);
        make.centerY.mas_equalTo(self.timeLabel.mas_centerY);
    }];
    
    [self.praiseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.numLabel.mas_left).offset(-3);
        make.centerY.mas_equalTo(self.timeLabel.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(35, 25));
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerImage.mas_right).offset(Detail_LeftWidth);
        make.top.mas_equalTo(self.commentLabel.mas_bottom).offset(8);
        make.bottom.mas_equalTo(self.timeLabel.mas_top).offset(-8);
    }];
}


#pragma mark - 点击更多
- (void)moreButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.detailItem.click_Open = sender.isSelected;
    
    if (self.moreButtonActionHandle) {
        self.moreButtonActionHandle(sender.selected,self.maxCommentLabelHeight);
    }
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
