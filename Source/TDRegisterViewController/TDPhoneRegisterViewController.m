//
//  TDPhoneRegisterViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/30.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDPhoneRegisterViewController.h"
#import "TDPasswordViewController.h"
#import "TDBaseToolModel.h"
#import "OEXFlowErrorViewController.h"
#import "edx-Swift.h"

@interface TDPhoneRegisterViewController ()<UIAlertViewDelegate>

@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UITextField *codeField;
@property (nonatomic,strong) UIButton *nextButton;
@property (nonatomic,strong) UIButton *resendButton;

@property (nonatomic,assign) int timeNum;
@property (nonatomic,strong) NSTimer *timer;//定时器

@property (nonatomic,strong) UIActivityIndicatorView *activityView;
@property (nonatomic,strong) TDBaseToolModel *baseTool;

@end

@implementation TDPhoneRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setViewConstraint];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"PHONE_REGISTER", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    [self cutDownTime];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
    [self.codeField resignFirstResponder];
    [self.activityView stopAnimating];
}

#pragma mark -- 获取验证码
- (void)getVerificationCode {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    int num = (arc4random() % 1000000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];//六位数验证码
    self.randomNumber = randomNumber;
    
    NSString *message = [NSString stringWithFormat:@"您正在注册英荔账号，验证码为%@，5分钟内有效。",self.randomNumber];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.phoneStr forKey:@"mobile"];
    [params setValue:message forKey:@"msg"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/send_captcha_message_for_register/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        id code = dict[@"code"];
        
        if ([code intValue] == 403) {
            
            [self.timer invalidate];
            [self showPhoneNumberUsed];
            
        } else if([code intValue] == 200){
            //            [self.view makeToast:@"验证短信已成功发送，请查收" duration:1.08 position:CSToastPositionCenter];
            
        } else {
            [self.timer invalidate];
            NSLog(@"验证登录密码 -- %@",dict[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.timer invalidate];
        NSLog(@"%ld",(long)error.code);
    }];
}

#pragma mark - 已注册过
- (void)showPhoneNumberUsed {
    
    self.resendButton.userInteractionEnabled = YES;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"PHONE_NUMBER_HAS_BEEN_REGISTERED", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -- 倒计时
- (void)cutDownTime {
    
    self.resendButton.userInteractionEnabled = NO;
    self.timeNum = 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timeChange {
    
    self.resendButton.userInteractionEnabled = NO;
    self.timeNum -= 1;
    [self.resendButton setTitle:[NSString stringWithFormat:@"%d%@",self.timeNum,NSLocalizedString(@"SECOND", nil)] forState:UIControlStateNormal];
    if (self.timeNum <= 0) {
        [self.timer invalidate];
        self.resendButton.userInteractionEnabled = YES;
        [self.resendButton setTitle:NSLocalizedString(@"RESEND", nil) forState:UIControlStateNormal];
    }
}

#pragma mark - 下一步
- (void)nextButtonAction:(UIButton *)sender {
    if (![self.baseTool networkingState]) {
        return;
    }
    
    [self.codeField resignFirstResponder];
    
    if ([self.codeField.text isEqualToString:self.randomNumber]) {//验证码正确
        
        TDPasswordViewController *passwordVc = [[TDPasswordViewController alloc] init];
        passwordVc.whereFrom = TDSetPasswordFromPhone;
        passwordVc.acountStr = self.phoneStr;
        [self.navigationController pushViewController:passwordVc animated:YES];
        
        [self.activityView startAnimating];
        
    } else {
        [self.view makeToast:NSLocalizedString(@"VERIFICATION_CODE_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
    }
}

#pragma mark - 重新发送
- (void)resendButtonAction:(UIButton *)sender {
    
    if (![self.baseTool networkingState]) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        return;
    }
    
    [self getVerificationCode];
    [self cutDownTime];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.codeField resignFirstResponder];
}

#pragma mark - UI
- (void)configView {
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:15];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.messageLabel.text = NSLocalizedString(@"HAD_SEND_MESSAGE", nil);
    [self.view addSubview:self.messageLabel];
    
    self.codeField = [[UITextField alloc] init];
    self.codeField.placeholder = NSLocalizedString(@"PLEASE_ENTER_VERI", nil);
    self.codeField.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.codeField.borderStyle = UITextBorderStyleRoundedRect;
    self.codeField.font = [UIFont fontWithName:@"OpenSans" size:15];
    //    self.codeField.delegate = self;
    [self.view addSubview:self.codeField];
    
    self.resendButton = [[UIButton alloc] init];
    self.resendButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.resendButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:15];
    self.resendButton.layer.masksToBounds = YES;
    self.resendButton.layer.cornerRadius = 4.0;
    [self.resendButton setTitle:NSLocalizedString(@"RESEND", nil) forState:UIControlStateNormal];
    [self.resendButton addTarget:self action:@selector(resendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.resendButton];
    
    self.nextButton = [[UIButton alloc] init];
    self.nextButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    //    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.layer.masksToBounds = YES;
    self.nextButton.layer.cornerRadius = 4.0;
    [self.nextButton setTitle:NSLocalizedString(@"NEXT_TEST", nil) forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:self.activityView];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
