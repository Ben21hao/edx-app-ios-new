//
//  TDRegisterViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/30.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDRegisterViewController.h"
#import "TDPhoneRegisterViewController.h"
#import "TDPasswordViewController.h"
#import "OEXFlowErrorViewController.h"
#import "TDWebViewController.h"

#import "TDBaseToolModel.h"
#import "edx-Swift.h"
#import "OEXAuthentication.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

@interface TDRegisterViewController ()<UIAlertViewDelegate>

@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UITextField *accountTextField;
@property (nonatomic,strong) UIButton *nextButton;
@property (nonatomic,strong) UIButton *bottomButton;

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@property (nonatomic,strong) NSString *randomNumber;//本地随机生成的验证码

@end

@implementation TDRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setViewConstraint];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"REGISTER", nil);
    [self.leftButton addTarget:self action:@selector(leftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.activityView stopAnimating];
    [self.accountTextField resignFirstResponder];
}

#pragma mark - 下一步
- (void)nextButtonAction:(UIButton *)sender {
    
    [self.accountTextField resignFirstResponder];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        
        return;
        
    } else if (self.accountTextField.text.length == 0) {//为空
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"INPUT_ERROR", nil)
                                                                message:NSLocalizedString(@"ENTER_PHONE_OR_EMAIL", nil)
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        
    } else if (self.accountTextField.text.length > 0) {
        
        [self.activityView startAnimating];
        
        if ([baseTool isValidateMobile:self.accountTextField.text]) {//手机有效
            [self getPhoneVerificationCode];
            
        } else if ([baseTool isValidateEmail:self.accountTextField.text]) {//邮箱有效
            
            [self judEmailBeRegister];
            
        } else {
            [self.activityView stopAnimating];
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"INPUT_ERROR", nil)
                                                                    message:NSLocalizedString(@"ENTER_RIGHT_PHONE_OR_EMAIL", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
        }
    }
}

#pragma mark -- 获取手机验证码
- (void)getPhoneVerificationCode {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    int num = (arc4random() % 1000000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];//六位数验证码
    NSString *message = [NSString stringWithFormat:@"您正在注册英荔账号，验证码为%@，5分钟内有效。",randomNumber];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.accountTextField.text forKey:@"mobile"];
    [params setValue:message forKey:@"msg"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/send_captcha_message_for_register/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.activityView stopAnimating];
        NSDictionary *dict = (NSDictionary *)responseObject;
        id code = dict[@"code"];
        
        if ([code intValue] == 403) {
            
            [self showPhoneNumberUsed];
            
        } else if([code intValue] == 200){
            
            TDPhoneRegisterViewController *phoneVC = [[TDPhoneRegisterViewController alloc] init];
            phoneVC.phoneStr = self.accountTextField.text;
            phoneVC.randomNumber = randomNumber;
            [self.navigationController pushViewController:phoneVC animated:YES];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.activityView stopAnimating];
        NSLog(@"%ld",(long)error.code);
    }];
}

#pragma mark - 手机已注册过
- (void)showPhoneNumberUsed {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"PHONE_NUMBER_HAS_BEEN_REGISTERED", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil, nil];
    [alertView show];
}


#pragma mark - 判断邮箱是否被注册
- (void)judEmailBeRegister {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.accountTextField.text forKey:@"email"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/email_can_be_signup/",ELITEU_URL];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.activityView stopAnimating];
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        int codeInt = [code intValue];
        
        if (codeInt == 200) {
            
            TDPasswordViewController *passwordVc = [[TDPasswordViewController alloc] init];
            passwordVc.whereFrom = TDSetPasswordFromEmai;
            passwordVc.acountStr = self.accountTextField.text;
            [self.navigationController pushViewController:passwordVc animated:YES];
            
        } else if (codeInt == 303) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NEED_ACTIVITY", nil)
                                                                message:NSLocalizedString(@"SEND_EMAIL_ACTIVITY", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            [alertView show];
            
        } else if (codeInt == 301) {
            [self.view makeToast:NSLocalizedString(@"EMAIL_REGISTERED_LOGIN", nil) duration:1.08 position:CSToastPositionCenter];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            });
            
        } else if (codeInt == 302) {
            [self.view makeToast:responDic[@"msg"] duration:1.08 position:CSToastPositionCenter];
            
        } else {
            NSLog(@"邮箱注册 -- %@",responDic[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.activityView stopAnimating];
        NSLog(@"邮箱是否已注册 -- %ld",(long)error.code);
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self sendEmail];
    }
}

#pragma mark - 发邮件
- (void)sendEmail {
    [self.activityView startAnimating];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.accountTextField.text forKey:@"email"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/resend_active_email/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.activityView stopAnimating];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        [self.view makeToast:dict[@"msg"] duration:1.08 position:CSToastPositionCenter];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.activityView stopAnimating];
        NSLog(@"发邮件 -- %ld",(long)error.code);
    }];
}

#pragma mark - dismiss
- (void)leftButtonAction:(UIButton *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 服务条款
- (void)bottomButtonAtion:(UIButton *)sender {
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        
        return;
        
    }
    
    TDWebViewController *webViewcontroller = [[TDWebViewController alloc] init];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"stipulation" withExtension:@"htm"];
    webViewcontroller.url = url;
    webViewcontroller.titleStr = NSLocalizedString(@"SERVICE_ITEM", nil);
    [self.navigationController pushViewController:webViewcontroller animated:YES];
}

#pragma mark - 点击页面
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.accountTextField resignFirstResponder];
}

#pragma mark - UI
- (void)configView {
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:15];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.messageLabel.text = NSLocalizedString(@"PHONE_OR_EMAIL_REGISTER", nil);
    self.messageLabel.numberOfLines = 0;
    [self.view addSubview:self.messageLabel];
    
    self.accountTextField = [[UITextField alloc] init];
    self.accountTextField.placeholder = NSLocalizedString(@"PHONE_OR_EMAIL", nil);
    self.accountTextField.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.accountTextField.font = [UIFont fontWithName:@"OpenSans" size:15];
    self.accountTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.accountTextField];
    
    self.nextButton = [[UIButton alloc] init];
    self.nextButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.nextButton.layer.cornerRadius = 4.0;
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.nextButton setTitle:NSLocalizedString(@"NEXT_TEST", nil) forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    
    self.bottomButton = [[UIButton alloc] init];
    [self.bottomButton setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    self.bottomButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomButton.titleLabel.numberOfLines = 0;
    self.bottomButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    [self.bottomButton addTarget:self action:@selector(bottomButtonAtion:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButton setAttributedTitle:[self setAttribute] forState:UIControlStateNormal];
    [self.view addSubview:self.bottomButton];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:self.activityView];
}

- (void)setViewConstraint {
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.top.mas_equalTo(self.view.mas_top).offset(18);
    }];
    
    [self.accountTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(41);
    }];
    
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.accountTextField.mas_bottom).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(41);
    }];
    
    [self.bottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX).offset(0);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-18);
        make.right.mas_equalTo(self.view.mas_right).offset(-8);
        make.height.mas_equalTo(39);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.nextButton.mas_centerY);
        make.right.mas_equalTo(self.nextButton.mas_right).offset(-8);
    }];
}

#pragma mark - attribute
- (NSMutableAttributedString *)setAttribute {
    NSString *str = [NSString stringWithFormat:@"%@\n",NSLocalizedString(@"SIGN_UP_AGREE", nil)];
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr8]}];
    
    NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"AGREEMENT", nil) attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr1]}];
    [str1 appendAttributedString:str2];
    return str1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
