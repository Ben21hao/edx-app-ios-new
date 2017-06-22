//
//  TDAlertView.m
//  edX
//
//  Created by Elite Edu on 17/1/19.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDAlertView.h"

#define CORNER_RADIUS 8.0

@interface TDAlertView () <UITextFieldDelegate>

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIView *alertView;
@property (nonatomic,strong) UILabel *title;
@property (nonatomic,strong) UIView *inputView;
@property (nonatomic,strong) UILabel *line1;
@property (nonatomic,strong) UILabel *line2;
@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) UIButton *sureButton;
@property (nonatomic,strong) UITextField *textField;
@property (nonatomic,strong) UIButton *eyeButton;

@end

@implementation TDAlertView

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self configView];
        [self setViewConstraint];
    }
    return self;
}

- (void)setVertifiFailed:(BOOL)vertifiFailed {
    _vertifiFailed = vertifiFailed;
    
    self.errorLabel.hidden = !vertifiFailed;
    
    [self.alertView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY).offset(-29);
        make.left.mas_equalTo(self.mas_left).offset(29);
        make.right.mas_equalTo(self.mas_right).offset(-29);
        make.height.mas_equalTo(vertifiFailed ? 183 : 149);
    }];
}

#pragma mark - UI
- (void)configView {
    
    self.bgView = [[UIView alloc] init];
    self.bgView.backgroundColor = [UIColor blackColor];
    self.bgView.alpha = 0.3;
    [self addSubview:self.bgView];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewAction)];
    [self.bgView addGestureRecognizer:gesture];
    
    self.alertView = [[UIView alloc] init];
    self.alertView.backgroundColor = [UIColor whiteColor];
    self.alertView.layer.cornerRadius = CORNER_RADIUS;
    [self addSubview:self.alertView];
    
    self.title = [[UILabel alloc] init];
    self.title.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.title.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.text = NSLocalizedString(@"SECURITY_VALIDATION", nil);
    [self.alertView addSubview:self.title];
    
    self.inputView = [[UIView alloc] init];
    self.inputView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.inputView.layer.masksToBounds = YES;
    self.inputView.layer.borderColor = [UIColor colorWithHexString:colorHexStr7].CGColor;
    self.inputView.layer.borderWidth = 0.5;
    self.inputView.layer.cornerRadius = 4.0;
    [self.alertView addSubview:self.inputView];
    
    self.line1 = [[UILabel alloc] init];
    self.line1.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [self.alertView addSubview:self.line1];
    
    self.line2 = [[UILabel alloc] init];
    self.line2.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [self.alertView addSubview:self.line2];
    
    self.cancelButton = [[UIButton alloc] init];
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"16" size:16];
    self.cancelButton.layer.cornerRadius = CORNER_RADIUS;
    [self.cancelButton setTitle:NSLocalizedString(@"CANCEL", nil) forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor colorWithHexString:colorHexStr8] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.alertView addSubview:self.cancelButton];
    
    self.sureButton = [[UIButton alloc] init];
    self.sureButton.titleLabel.font = [UIFont fontWithName:@"16" size:16];
    self.sureButton.layer.cornerRadius = CORNER_RADIUS;
    [self.sureButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    [self.sureButton setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    [self.sureButton addTarget:self action:@selector(sureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.alertView addSubview:self.sureButton];
    
    self.textField = [[UITextField alloc] init];
    self.textField.delegate = self;
    self.textField.secureTextEntry = YES;
    self.textField.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.textField.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.textField.placeholder = NSLocalizedString(@"LOGIN_PASSWORD", nil);
    [self.inputView addSubview:self.textField];
    
    self.eyeButton = [[UIButton alloc] init];
    self.eyeButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:20];
    [self.eyeButton setTitleColor:[UIColor colorWithHexString:colorHexStr8] forState:UIControlStateNormal];
    [self.eyeButton setTitle:@"\U0000f070" forState:UIControlStateNormal];
    [self.eyeButton addTarget:self action:@selector(eyeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.inputView addSubview:self.eyeButton];
    
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.textColor = [UIColor colorWithHexString:@"#F47676"];
    [self.alertView addSubview:self.errorLabel];
    
    self.errorLabel.hidden = YES;
}

- (void)setViewConstraint {
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    [self.alertView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY).offset(-29);
        make.left.mas_equalTo(self.mas_left).offset(29);
        make.right.mas_equalTo(self.mas_right).offset(-29);
        make.height.mas_equalTo(149);
    }];
    
    [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.alertView);
        make.top.mas_equalTo(self.alertView.mas_top).offset(3);
        make.height.mas_equalTo(39);
    }];
    
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.title.mas_bottom).offset(5);
        make.left.mas_equalTo(self.alertView.mas_left).offset(11);
        make.right.mas_equalTo(self.alertView.mas_right).offset(-11);
        make.height.mas_equalTo(39);
    }];
    
    [self.line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        //        make.top.mas_equalTo(self.inputView.mas_bottom).offset(15);
        make.bottom.mas_equalTo(self.alertView.mas_bottom).offset(-48);
        make.left.right.mas_equalTo(self.alertView);
        make.height.mas_equalTo(0.5);
    }];
    
    [self.line2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.line1.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.alertView.mas_bottom).offset(0);
        make.centerX.mas_equalTo(self.alertView.mas_centerX);
        make.width.mas_equalTo(0.5);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.alertView.mas_left).offset(0);
        make.top.mas_equalTo(self.line1.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.alertView.mas_bottom).offset(0);
        make.right.mas_equalTo(self.line2.mas_left).offset(0);
    }];
    
    [self.sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.line2.mas_right).offset(0);
        make.top.mas_equalTo(self.line1.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.alertView.mas_bottom).offset(0);
        make.right.mas_equalTo(self.alertView.mas_right).offset(0);
    }];
    
    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(self.inputView);
        make.left.mas_equalTo(self.inputView.mas_left).offset(8);
        make.right.mas_equalTo(self.inputView.mas_right).offset(-39);
    }];
    
    [self.eyeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.inputView.mas_centerY);
        make.right.mas_equalTo(self.inputView.mas_right).offset(-5);
        make.size.mas_equalTo(CGSizeMake(29, 29));
    }];
    
    [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.alertView);
        make.top.mas_equalTo(self.inputView.mas_bottom).offset(3);
        make.bottom.mas_equalTo(self.line1.mas_top).offset(-3);
    }];
}

#pragma mark - textField delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    self.errorLabel.hidden = YES;
    
    int topHeight = 29;
    if (self.bounds.size.height / 2 < TDKeybordHeight + 115) {
        
        topHeight = TDKeybordHeight + 115 - self.bounds.size.height / 2;
        
        //        [self.alertView mas_remakeConstraints:^(MASConstraintMaker *make) {
        //            make.centerY.mas_equalTo(self.mas_centerY).offset(-topHeight);
        //            make.left.mas_equalTo(self.mas_left).offset(29);
        //            make.right.mas_equalTo(self.mas_right).offset(-29);
        //            make.height.mas_equalTo(149);
        //        }];
    }
    [self.alertView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY).offset(-topHeight);
        make.left.mas_equalTo(self.mas_left).offset(29);
        make.right.mas_equalTo(self.mas_right).offset(-29);
        make.height.mas_equalTo(149);
    }];
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if (self.bounds.size.height / 2 < TDKeybordHeight + 115) {
        [self.alertView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.mas_centerY).offset(-29);
            make.left.mas_equalTo(self.mas_left).offset(29);
            make.right.mas_equalTo(self.mas_right).offset(-29);
            make.height.mas_equalTo(149);
        }];
    }
    return YES;
}

#pragma mark - 明文 - 密文
- (void)eyeButtonAction:(UIButton *)sender {
    
    self.textField.secureTextEntry = !self.textField.secureTextEntry;
    if (self.textField.secureTextEntry == YES) {
        [self.eyeButton setTitle:@"\U0000f070" forState:UIControlStateNormal];
        
    } else {
        [self.eyeButton setTitle:@"\U0000f06e" forState:UIControlStateNormal];
    }
}

#pragma mark - 确定
- (void)sureButtonAction:(UIButton *)sender {
    [self.textField resignFirstResponder];
    if (self.sureHandle) {
        self.sureHandle(self.textField.text);
    }
}

#pragma mark - 取消
- (void)cancelButtonAction:(UIButton *)sender {
    [self.textField resignFirstResponder];
    if (self.cancelHandle) {
        self.cancelHandle();
    }
}

#pragma mark - 点击空白处
- (void)tapViewAction {
    [self.textField resignFirstResponder];
}

@end




