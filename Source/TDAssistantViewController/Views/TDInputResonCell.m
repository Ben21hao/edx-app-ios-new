//
//  TDInputResonCell.m
//  edX
//
//  Created by Elite Edu on 17/3/2.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDInputResonCell.h"

@interface TDInputResonCell () <UITextViewDelegate>

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *numLabel;
@property (nonatomic,strong) UITextView *inputTextView;
@property (nonatomic,strong) UILabel *holderLabel;

@end

@implementation TDInputResonCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.holderLabel.hidden = YES;
    if (self.inputViewResponderHandle) {
        self.inputViewResponderHandle(YES);
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.numLabel.text = [NSString stringWithFormat:@"%ld/500",(unsigned long)textView.text.length];
    if (textView.text.length > 500) {
        self.numLabel.textColor = [UIColor redColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.inputTextView.text.length > 0) {
        self.holderLabel.hidden = YES;
    } else {
        self.holderLabel.hidden = NO;
    }
    
    if (self.inputViewResponderHandle) {
        self.inputViewResponderHandle(NO);
    }
    if (self.inputStrHandle) {
        self.inputStrHandle(self.inputTextView.text);
    }
}

#pragma mark - UI
- (void)configView {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bgView];
    
    self.titleLabel = [self setLabelConstraint:NSLocalizedString(@"RETE_TA", nil)];
    [self.bgView addSubview:self.titleLabel];
    
    self.numLabel = [self setLabelConstraint:@"0/500"];
    [self.bgView addSubview:self.numLabel];
    
    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.delegate = self;
    self.inputTextView.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.inputTextView.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.inputTextView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.inputTextView.layer.masksToBounds = YES;
    self.inputTextView.layer.cornerRadius = 4.0;
    self.inputTextView.layer.borderWidth = 0.5;
    self.inputTextView.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    [self.bgView addSubview:self.inputTextView];
    
    self.holderLabel = [self setLabelConstraint:NSLocalizedString(@"ENTER_COMMENTS_TA", nil)];
    self.holderLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.bgView addSubview:self.holderLabel];
}

- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.bgView.mas_left).offset(11);
        make.top.mas_equalTo(self.bgView.mas_top).offset(8);
        make.height.mas_equalTo(28);
    }];
    
    [self.numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.bgView.mas_right).offset(-11);
        make.top.mas_equalTo(self.bgView.mas_top).offset(8);
        make.height.mas_equalTo(28);
    }];
    
    [self.inputTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.mas_equalTo(self.bgView.mas_left).offset(18);
        make.right.mas_equalTo(self.bgView.mas_right).offset(-18);
        make.bottom.mas_equalTo(self.bgView.mas_bottom).offset(-11);
    }];
    
    [self.holderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.inputTextView.mas_left).offset(8);
        make.top.mas_equalTo(self.inputTextView.mas_top).offset(8);
    }];
}

- (UILabel *)setLabelConstraint:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:14];
    label.textColor = [UIColor colorWithHexString:colorHexStr10];
    label.text = title;
    return label;
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
