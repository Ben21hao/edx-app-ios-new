//
//  TDPhoneSendNumResetViewController.m
//  edX
//
//  Created by Ben on 2017/5/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDPhoneSendNumResetViewController.h"
#import "TDPasswordResetViewController.h"
#import "TDBaseToolModel.h"
#import "OEXFlowErrorViewController.h"
#import "edx-Swift.h"

@interface TDPhoneSendNumResetViewController () <UIAlertViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UITextField *codeField;
@property (nonatomic,strong) UIButton *nextButton;
@property (nonatomic,strong) UIButton *resendButton;

@property (nonatomic,assign) int timeNum;
@property (nonatomic,strong) NSTimer *timer;//定时器

@property (nonatomic,strong) UIActivityIndicatorView *activityView;
@property (nonatomic,strong) UIActivityIndicatorView *codeActivitView;

@property (nonatomic,strong) UIButton *leftButton;

@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDPhoneSendNumResetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setLeftNavigationBar];
    
    [self configView];
    [self setViewConstraint];
    
    self.toolModel = [[TDBaseToolModel alloc] init];
    [self cutDownTime];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground) name:@"App_EnterForeground_Get_Code" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"RESET_BY_PHONE", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
    self.resendButton.userInteractionEnabled = YES;
    [self.resendButton setTitle:NSLocalizedString(@"RESEND", nil) forState:UIControlStateNormal];
    
    [self.codeField resignFirstResponder];
    [self.activityView stopAnimating];
}

#pragma mark - 导航栏左边按钮
- (void)setLeftNavigationBar {
    
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [self.leftButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    self.leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    [self.leftButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftButton];
}

- (void)backButtonAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark  - 找回密码--发送验证码请求
- (void)phoneForCheckNum {
    
    [self handleResendButton:NO];
    
    int num = (arc4random() % 1000000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];
    self.randomNumber = randomNumber;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *message = [NSString stringWithFormat:@"您正在重置密码，验证码为%@，5分钟内有效，请勿泄露。",self.randomNumber];
    params[@"msg"] = message;
    params[@"mobile"] = self.phoneStr;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/send_captcha_message_for_reset_password/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [responseObject writeToFile:@"/Users/Eliteu/Desktop/pli/ta.plist" atomically:YES];
        NSDictionary *dict = responseObject;
        id code = dict[@"code"];
        
        if ([code integerValue] == 200) {
            
            [self cutDownTime];
            
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"SENT", nil)
                                                                    message:NSLocalizedString(@"PASSWORD_RESET_AUTHENTICATION_SENT", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
            
        }else if ([code intValue] == 403){//手机没注册
            [self handleResendButton:YES];
            
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:@""
                                                                    message:NSLocalizedString(@"PHONE_NUMBER_NOT_REGISTER", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
            
            
        } else {
            [self handleResendButton:YES];
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"RESET_FAILED", nil)
                                                                    message:NSLocalizedString(@"RESET_FAILED", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self handleResendButton:YES];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"-------->>> %ld",(long)error.code);
    }];
}

- (void)handleResendButton:(BOOL)isEnable {
    
    isEnable ? [self.codeActivitView stopAnimating] : [self.codeActivitView startAnimating];
    self.resendButton.userInteractionEnabled = isEnable;
    [self.resendButton setTitle:isEnable ? NSLocalizedString(@"RESEND", nil) : @"" forState:UIControlStateNormal];
}

- (void)appEnterForeground {
    self.timeNum = [self.toolModel getFreeCourseSecond:@"Get_Code_Date_Str"];
}

#pragma mark -- 倒计时
- (void)cutDownTime {
    
    self.resendButton.userInteractionEnabled = NO;
    
    self.timeNum = 60;
    
    NSString *timeStr = [self.toolModel addSecondsForNow:[NSNumber numberWithInteger:60]];
    [[NSUserDefaults standardUserDefaults] setValue:timeStr forKey:@"Get_Code_Date_Str"]; //结束时间 = 当前时间 + 剩余秒数
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timeChange {
    
    self.resendButton.userInteractionEnabled = NO;
    self.timeNum -= 1;
    
    [self.codeActivitView stopAnimating];
    [self.resendButton setTitle:[NSString stringWithFormat:@"%d%@",self.timeNum,NSLocalizedString(@"SECOND", nil)] forState:UIControlStateNormal];
    
    if (self.timeNum <= 0) {
        [self.timer invalidate];
        [self handleResendButton:YES];
    }
}

#pragma mark - 下一步
- (void)nextButtonAction:(UIButton *)sender {
    
    [self.codeField resignFirstResponder];
    
    if (![self.toolModel networkingState]) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        return;
    }
    if (self.codeField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"PLEASE_ENTER_VERI", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if ([self.codeField.text isEqualToString:self.randomNumber]) {//验证码正确
        
        TDPasswordResetViewController *passwordVc = [[TDPasswordResetViewController alloc] init];
        passwordVc.acountStr = self.phoneStr;
        [self.navigationController pushViewController:passwordVc animated:YES];
        
        [self.activityView startAnimating];
        
    } else {
        [self.view makeToast:NSLocalizedString(@"VERIFICATION_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
    }
}

#pragma mark - 重新发送
- (void)resendButtonAction:(UIButton *)sender {
    [self.codeField resignFirstResponder];
    
    if (![self.toolModel networkingState]) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        return;
    }
    
    [self phoneForCheckNum];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.codeField resignFirstResponder];
}

#pragma mark - UI
- (void)configView {
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.messageLabel.text = NSLocalizedString(@"HAD_SEND_MESSAGE", nil);
    [self.view addSubview:self.messageLabel];
    
    self.codeField = [[UITextField alloc] init];
    self.codeField.placeholder = NSLocalizedString(@"PLEASE_ENTER_VERI", nil);
    self.codeField.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.codeField.borderStyle = UITextBorderStyleRoundedRect;
    self.codeField.font = [UIFont fontWithName:@"OpenSans" size:15];
    [self.view addSubview:self.codeField];
    
    self.resendButton = [[UIButton alloc] init];
    self.resendButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.resendButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:15];
    self.resendButton.layer.masksToBounds = YES;
    self.resendButton.layer.cornerRadius = 4.0;
    [self.resendButton setTitle:NSLocalizedString(@"GET_VERIFICATION", nil) forState:UIControlStateNormal];
    [self.resendButton addTarget:self action:@selector(resendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.resendButton];
    
    self.nextButton = [[UIButton alloc] init];
    self.nextButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.layer.cornerRadius = 4.0;
    [self.nextButton setTitle:NSLocalizedString(@"NEXT_TEST", nil) forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:self.activityView];
    
    self.codeActivitView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.codeActivitView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:self.codeActivitView];
}

- (void)setViewConstraint {
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.view.mas_top).offset(18);
    }];
    
    [self.resendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.size.mas_equalTo(CGSizeMake(88, 41));
    }];
    
    [self.codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(18);
        make.right.mas_equalTo(self.resendButton.mas_left).offset(-3);
        make.height.mas_equalTo(41);
    }];
    
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.codeField.mas_bottom).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(41);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.nextButton.mas_centerY);
        make.right.mas_equalTo(self.nextButton.mas_right).offset(-8);
    }];
    
    [self.codeActivitView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.resendButton.mas_centerY);
        make.centerX.mas_equalTo(self.resendButton.mas_centerX);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
