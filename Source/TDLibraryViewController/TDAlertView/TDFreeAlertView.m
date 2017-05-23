//
//  TDFreeAlertView.m
//  edX
//
//  Created by Elite Edu on 17/3/15.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDFreeAlertView.h"
#import "TDRequestBaseModel.h"
#import "TDBaseToolModel.h"

#import "edX-Swift.h"
#import "OEXFlowErrorViewController.h"
#import "OEXAnalytics.h"
#import "OEXAuthentication.h"

#define USER_LOGIN_NAME @"User_Login_Name"
#define USER_LOGIN_PASSWORD @"User_Login_Password"

@interface TDFreeAlertView () <UITextFieldDelegate>

@property (nonatomic,strong) UIView *bgView;
@property (nonatomic,strong) UIView *messageView;
@property (nonatomic,strong) UIView *phoneBgView;
@property (nonatomic,strong) UIView *codeBgView;

@property (nonatomic,strong) UILabel *topLabel;
@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UILabel *errorLabel;

@property (nonatomic,strong) UIButton *codeButton;
@property (nonatomic,strong) UIButton *cancelButton;
@property (nonatomic,strong) UIButton *sureButton;

@property (nonatomic,strong) UITextField *phoneTextField;
@property (nonatomic,strong) UITextField *codeTextFiled;

@property (nonatomic,strong) UILabel *line1;
@property (nonatomic,strong) UILabel *line2;
@property (nonatomic,strong) UILabel *line3;
@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@property (nonatomic,strong) UITextField *otherTextField;//用来过渡的

@property (nonatomic,assign) CGFloat alertHeight;
@property (nonatomic,strong) NSString *phoneStr;
@property (nonatomic,strong) NSString *password;

@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) NSInteger timeNum;
@property (nonatomic,strong) NSString *randomNumber;//验证码
@property (nonatomic,assign) NSInteger type;

@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDFreeAlertView

- (instancetype)initWitType:(NSInteger)type {
    self = [super init];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.toolModel = [[TDBaseToolModel alloc] init];
        [self configView:type];
        [self setViewConstraint:type];
        self.type = type;
    }
    return self;
}

#pragma mark - textField delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField { //开始编辑
    
    self.otherTextField = textField;
    
    if ((TDHeight / 2  - self.alertHeight / 2) < TDKeybordHeight) {//如果高度比键盘高度的低
        
        [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.mas_left).offset(18);
            make.right.mas_equalTo(self.mas_right).offset(-18);
            make.bottom.mas_equalTo(self.mas_bottom).offset(-TDKeybordHeight);
            make.height.mas_equalTo(self.alertHeight);
        }];
    }
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField { //结束编辑
    
    /* 电话号码是否错误 */
    BOOL isErrorPhone = NO;
    if (self.phoneTextField.text.length > 0) {
        if (![self.toolModel isValidateMobile:self.phoneTextField.text]) {
            isErrorPhone = YES;
        }
    }
    
    /* 结束编辑的是否是同一个框 */
    BOOL isSame = NO;
    if ([self.otherTextField isEqual:textField]) {
        isSame = YES;
    }
    
    [self remarkAlertView:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil) error:isErrorPhone isSame:isSame];
    
    return YES;
}

#pragma mark - 重置UI
- (void)remarkAlertView:(NSString *)errorStr error:(BOOL)isError isSame:(BOOL)isSame {
    
    /* 点好号码错误就高点 */
    self.alertHeight = isError ? 258 : 228;
    
    CGFloat height = isSame ? -(TDHeight / 2  - self.alertHeight / 2) : -TDKeybordHeight;
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).offset(18);
        make.right.mas_equalTo(self.mas_right).offset(-18);
        make.bottom.mas_equalTo(self.mas_bottom).offset(height);
        make.height.mas_equalTo(self.alertHeight);
    }];
    
    self.errorLabel.text = errorStr;
    self.errorLabel.hidden = !isError;
        
    [self.errorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(isError ? 8 : 0);
        make.left.mas_equalTo(self.messageView.mas_left).offset(11);
        make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
        make.height.mas_equalTo(isError ? 39 : 0);
    }];
}

- (void)remarkAlerViewAfterRequest:(NSString *)errorStr {
    
    self.alertHeight = 258;
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).offset(18);
        make.right.mas_equalTo(self.mas_right).offset(-18);
        make.bottom.mas_equalTo(self.mas_bottom).offset(-(TDHeight / 2  - self.alertHeight / 2));
        make.height.mas_equalTo(self.alertHeight);
    }];
    
    self.errorLabel.text = errorStr;
    self.errorLabel.hidden = NO;
    
    [self.errorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(8);
        make.left.mas_equalTo(self.messageView.mas_left).offset(11);
        make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
        make.height.mas_equalTo(39);
    }];

}

#pragma mark - Action
- (void)resignFirstResponderAction {
    [self.phoneTextField resignFirstResponder];
    [self.codeTextFiled resignFirstResponder];
}

- (void)codeButtonAction:(UIButton *)sender { //获取验证码
    
    [self resignFirstResponderAction];
    self.phoneStr = self.phoneTextField.text;
    
    if (![self.toolModel networkingState]) { //无网络
        return;
        
    } else if (self.phoneStr.length == 0) {
        [self remarkAlerViewAfterRequest:NSLocalizedString(@"PHONE_IS_EMPTY", nil)];
        
    } else if (![self.toolModel isValidateMobile:self.phoneStr]) {
        [self remarkAlerViewAfterRequest:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil)];
        
    } else {
        /* 计时器 */
        self.timeNum = 60;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
        
        self.codeButton.userInteractionEnabled = NO;
        
        /* 验证码 */
        int num = (arc4random() % 1000000);
        NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];//六位数验证码
        self.randomNumber = randomNumber;
//        self.randomNumber = @"111111";
        NSString *msgStr = [NSString stringWithFormat:@"验证码：%@，5分钟内有效。您将获取每门课程30分钟的免费试听资格。充分体验课程，注意避免同时试听。",self.randomNumber];
        
        TDRequestBaseModel *requestModel = [[TDRequestBaseModel alloc] init];
        WS(weakSelf);
        requestModel.sendMsgHandle = ^(NSInteger type){
            if (type > 0) {
                [weakSelf setCodeButtonUserEnabled:1];
                NSString *errorStr = type == 1 ? NSLocalizedString(@"PHONE_HAD_REGITSTER", nil) : NSLocalizedString(@"FAILED_GET_VERIFICATION", nil);
                [weakSelf remarkAlerViewAfterRequest:errorStr];
            }
        };
        [requestModel sendVerificationMsg:msgStr phoneStr:self.phoneStr];
    }
}

- (void)timeChange {
    self.timeNum -= 1;
    [self.codeButton setTitle:[NSString stringWithFormat:@"%ld%@",(long)self.timeNum,NSLocalizedString(@"SECOND", nil)] forState:UIControlStateNormal];
    
    if (self.timeNum < 0) {
        [self setCodeButtonUserEnabled:0];
    }
}

- (void)dealloc {
    [self.timer invalidate];
}

- (void)setCodeButtonUserEnabled:(NSInteger)type {
    [self.timer invalidate];
    [self.codeButton setTitle:type == 0 ? NSLocalizedString(@"RESEND", nil) : NSLocalizedString(@"GET_VERIFICATION", nil) forState:UIControlStateNormal];
    self.codeButton.userInteractionEnabled = YES;
}

- (void)cancelButtonAction:(UIButton *)sender {
    
    if (self.type == 0) {//取消
        [self resignFirstResponderAction];
        [self.timer invalidate];
        
    } else {//结束试听
        
    }
    
    if (self.cancelButtonHandle) {
        self.cancelButtonHandle();
    }
}

- (void)sureButtonAction:(UIButton *)sender {
    
    if (self.type == 0) { //立即试听
        
        [self resignFirstResponderAction];
//        [self setCodeButtonUserEnabled];
        
        if (![self.toolModel networkingState]) { //无网络
            return;
        } else if (self.phoneTextField.text.length == 0) {
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"PHONE_IS_EMPTY", nil)];
            
        } else if (self.codeTextFiled.text.length == 0) {
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"PLEASE_ENTER_VERI", nil)];
            
        } else if (![self.toolModel isValidateMobile:self.phoneTextField.text]) { //手机号码不正确
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil)];
            
        } else if (self.phoneStr.length == 0) {//手机号码还没获取验证码
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"STILL_NO_GET_VERI", nil)];
            
        } else if (![self.codeTextFiled.text isEqualToString:self.randomNumber]) {//验证码不正确
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"VERIFICATION_CODE_ERROR", nil)];
            
        } else if (![self.phoneStr isEqualToString:self.phoneTextField.text]) {//修改手机号码，请重新获取验证码。
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"MOBILE_CHANGED", nil)];
            
        } else {
            [self regitsterNewUser]; //立即试听
        }
        
    } else {//立即加入
        if (self.sureButtonHandle) {
            self.sureButtonHandle();
        }
    }
}

/* 立即试听 */
- (void)regitsterNewUser {

    [self.activityView startAnimating];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.phoneStr forKey:@"mobile"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/listening_course_by_mobile/",ELITEU_URL];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        int code = [responseDic[@"code"] intValue];
        
        if (code == 200) {
            
            self.password = responseDic[@"data"][@"user"][@"password"];
            [self beginLogin:self.phoneTextField.text password:self.password];
            
        } else if (code == 301) {//开通试用失败
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"PHONE_HAD_REGITSTER", nil)];
            
        } else if (code == 310) {//手机号码格式不正确
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil)];
            
        } else if (code == 322) {//手机号码已存在，不能注册
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"PHONE_NUMBER_HAS_BEEN_REGISTERED", nil)];
            
        } else {
            [self remarkAlerViewAfterRequest:NSLocalizedString(@"PHONE_HAD_REGITSTER", nil)];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self remarkAlerViewAfterRequest:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil)];
    }];
}

#pragma mark - 登录相关操作
- (void)beginLogin:(NSString *)account password:(NSString *)password {
    
    [OEXAuthentication requestTokenWithUser:account password:password completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                            
                              [self handleLoginResponseWith:data response:response error:error];
        
                          }];
}

- (void)handleLoginResponseWith:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    
    [self.activityView stopAnimating];
    
    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        
        if(httpResp.statusCode == 200) {
            [self loginSuccessful];//登录成功
            
        } else if(httpResp.statusCode >= 400 && httpResp.statusCode <= 500) {
            NSString *errorStr = [Strings invalidUsernamePassword];
            [self loginFailedWithErrorMessage:errorStr title:nil];//登录失败
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            });
        }
    } else {
        [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
    }
}

#pragma mark - 登录失败处理
- (void)loginFailedWithErrorMessage:(NSString*)errorStr title:(NSString*)title {
    
    if(title) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:title
                                                                message:errorStr
                                                       onViewController:self
                                                             shouldHide:YES];
    } else {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:errorStr
                                                       onViewController:self
                                                             shouldHide:YES];
    }
}

#pragma mark - 登录成功
- (void)loginSuccessful {
    
    if([self.phoneTextField.text length] > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.phoneTextField.text forKey:USER_LOGIN_NAME]; //存储用户名
//        [[OEXAnalytics sharedAnalytics] trackUserLogin:[self.authProvider backendName] ?: @"Password"];// Analytics User Login
    }
    
    if (self.password.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:self.password forKey:USER_LOGIN_PASSWORD];
    }
    
     //直接跳转学习界面
    if (self.sureButtonHandle) {
        self.sureButtonHandle();
    }
}

#pragma mark - UI
- (void)configView:(NSInteger)type {
    
    NSString *titleStr = type == 0 ? NSLocalizedString(@"START_FREE_COURSE", nil) : NSLocalizedString(@"FREE_TRIAL_ENDED", nil);
    NSString *messageStr = type == 0 ? NSLocalizedString(@"MOBILE_USED_ACOUNT", nil) : NSLocalizedString(@"FREE_ENDED_ENROLL", nil);
    NSString *cancelStr = type == 0 ? NSLocalizedString(@"CANCEL", nil) : NSLocalizedString(@"FREE_QUIT", nil);
    NSString *sureStr = type == 0 ? NSLocalizedString(@"FREE_START", nil) : NSLocalizedString(@"FREE_ENROLL", nil);
    
    self.otherTextField = [[UITextField alloc] init];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFirstResponderAction)];
    [self addGestureRecognizer:tap1];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFirstResponderAction)];
    
    self.bgView = [[UIView alloc] init];
    [self.bgView addGestureRecognizer:tap];
    self.bgView.backgroundColor = [UIColor whiteColor];
    self.bgView.layer.cornerRadius = 4.0;
    [self addSubview:self.bgView];
    
    self.topLabel = [self setLabel:titleStr font:16 color:colorHexStr10];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    [self.bgView addSubview:self.topLabel];
    
    self.line1 = [[UILabel alloc] init];
    self.line1.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [self.bgView addSubview:self.line1];
    
    self.line2 = [[UILabel alloc] init];
    self.line2.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [self.bgView addSubview:self.line2];
    
    self.line3 = [[UILabel alloc] init];
    self.line3.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [self.bgView addSubview:self.line3];
    
    self.cancelButton = [self setButton:cancelStr color:colorHexStr11 titleColor:colorHexStr9];
    [self.cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.cancelButton];
    
    self.sureButton = [self setButton:sureStr color:colorHexStr11 titleColor:colorHexStr2];
    [self.sureButton addTarget:self action:@selector(sureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.sureButton];
    
    //内容视图
    self.messageView = [[UIView alloc] init];
    [self.bgView addSubview:self.messageView];
    
    self.messageLabel = [self setLabel:messageStr font:14 color:colorHexStr9];
    [self.messageView addSubview:self.messageLabel];
    
    if (type == 0) {
        
        self.phoneBgView = [self setInputBgView];
        [self.messageView addSubview:self.phoneBgView];
        
        self.codeBgView = [self setInputBgView];
        [self.messageView addSubview:self.codeBgView];
        self.phoneTextField = [ self setTextField:NSLocalizedString(@"PLEASE_ENTER_PHONE_NUMBER", nil)];
        [self.messageView addSubview:self.phoneTextField];
        
        self.codeTextFiled = [self setTextField:NSLocalizedString(@"PLEASE_ENTER_VERI", nil)];
        [self.messageView addSubview:self.codeTextFiled];
        
        self.codeButton = [self setButton:NSLocalizedString(@"GET_VERIFICATION", nil) color:colorHexStr2 titleColor:colorHexStr11];
        self.codeButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        [self.codeButton addTarget:self action:@selector(codeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.messageView addSubview:self.codeButton];
        
        self.errorLabel = [self setLabel:NSLocalizedString(@"VERIFICATION_CODE_ERROR", nil) font:14 color:colorHexStr3];
        self.errorLabel.textColor = [UIColor colorWithHexString:@"#F47676"];
        self.errorLabel.textAlignment = NSTextAlignmentCenter;
        self.errorLabel.numberOfLines = 0;
        [self.messageView addSubview:self.errorLabel];
        
    } else if (type == 1) {
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.numberOfLines = 0;
    }
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    [self.bgView addSubview:self.activityView];
}

- (void)setViewConstraint:(NSInteger)type {

    self.alertHeight = 228;
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.mas_left).offset(18);
        make.right.mas_equalTo(self.mas_right).offset(-18);
        make.bottom.mas_equalTo(self.mas_bottom).offset(-(TDHeight / 2  - self.alertHeight / 2));
        make.height.mas_equalTo(type == 0 ? 228 : 188);
    }];
    
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.bgView);
        make.top.mas_equalTo(self.bgView.mas_top).offset(8);
        make.height.mas_equalTo(28);
    }];
    
    [self.line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.bgView);
        make.height.mas_equalTo(0.5);
        make.top.mas_equalTo(self.topLabel.mas_bottom).offset(8);
    }];

    [self.line2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.bgView);
        make.top.mas_equalTo(self.bgView.mas_bottom).offset(-44);
        make.height.mas_equalTo(0.5);
    }];
    
    [self.line3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
        make.width.mas_equalTo(0.5);
        make.top.mas_equalTo(self.line2.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.bgView.mas_bottom).offset(0);
    }];
    
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.mas_equalTo(self.bgView);
        make.right.mas_equalTo(self.line3.mas_left).offset(0);
        make.top.mas_equalTo(self.line2.mas_bottom).offset(0);
    }];
    
    [self.sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.line3.mas_right).offset(0);
        make.top.mas_equalTo(self.line2.mas_bottom).offset(0);
        make.bottom.right.mas_equalTo(self.bgView);
    }];
    
    //中间的内容视图
    [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.bgView);
        make.top.mas_equalTo(self.line1.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.line2.mas_top).offset(0);
    }];
    
    if (type == 0) {
        
        [self.codeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.messageView.mas_top).offset(8);
            make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
            make.size.mas_equalTo(CGSizeMake(88, 39));
        }];
        
        [self.phoneBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.messageView.mas_top).offset(8);
            make.left.mas_equalTo(self.messageView.mas_left).offset(11);
            make.height.mas_equalTo(39);
            make.right.mas_equalTo(self.codeButton.mas_left).offset(-5);
        }];
        
        [self.codeBgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.messageView.mas_left).offset(11);
            make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
            make.top.mas_equalTo(self.phoneTextField.mas_bottom).offset(8);
            make.height.mas_equalTo(39);
        }];
        
        [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.phoneBgView.mas_top).offset(0);
            make.left.mas_equalTo(self.phoneBgView.mas_left).offset(5);
            make.height.mas_equalTo(39);
            make.right.mas_equalTo(self.phoneBgView.mas_right);
        }];
        
        [self.codeTextFiled mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.codeBgView.mas_left).offset(5);
            make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
            make.top.mas_equalTo(self.codeBgView.mas_top);
            make.height.mas_equalTo(39);
        }];
        
        [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.messageView.mas_left).offset(15);
            make.top.mas_equalTo(self.codeTextFiled.mas_bottom).offset(8);
            make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
        }];
        
        [self.errorLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(0);
            make.left.mas_equalTo(self.messageView.mas_left).offset(11);
            make.right.mas_equalTo(self.messageView.mas_right).offset(-11);
            make.height.mas_equalTo(0);
        }];
    } else if (type == 1) {
        
        [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.mas_equalTo(self.messageView);
        }];
    }
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.sureButton.mas_centerY);
        make.right.mas_equalTo(self.sureButton.mas_right).offset(-8);
    }];
}

- (UILabel *)setLabel:(NSString *)title font:(NSInteger)font color:(NSString *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:font];
    label.textColor = [UIColor colorWithHexString:color];
    label.text = title;
    return label;
}

- (UITextField *)setTextField:(NSString *)holdStr {
    
    UITextField *textField = [[UITextField alloc] init];
    textField.font = [UIFont fontWithName:@"OpenSans" size:14];
    textField.layer.cornerRadius = 4.0;
    textField.textColor = [UIColor colorWithHexString:colorHexStr10];
    textField.placeholder = holdStr;
    textField.delegate = self;
    return textField;
}

- (UIButton *)setButton:(NSString *)title color:(NSString *)color titleColor:(NSString *)titleColor {
    
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [UIColor colorWithHexString:color];
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    button.layer.cornerRadius = 4.0;
    button.showsTouchWhenHighlighted = YES;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithHexString:titleColor] forState:UIControlStateNormal];
    return button;
}

- (UIView *)setInputBgView {
    
    UIView *inputView = [[UIView alloc] init];
    inputView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    inputView.layer.masksToBounds = YES;
    inputView.layer.borderColor = [UIColor colorWithHexString:colorHexStr7].CGColor;
    inputView.layer.borderWidth = 0.5;
    inputView.layer.cornerRadius = 4.0;
    return inputView;
}

@end
