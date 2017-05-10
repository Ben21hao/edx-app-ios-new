//
//  TDResetPasswordViewController.m
//  edX
//
//  Created by Ben on 2017/5/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDResetPasswordViewController.h"
#import "TDPhoneSendNumResetViewController.h"
#import "TDEmailResetViewController.h"
#import "OEXFlowErrorViewController.h"
#import "TDWebViewController.h"

#import "TDBaseToolModel.h"
#import "OEXAuthentication.h"
#import "edx-Swift.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

@interface TDResetPasswordViewController ()

@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UITextField *accountTextField;
@property (nonatomic,strong) UIButton *nextButton;
@property (nonatomic,strong) UIButton *bottomButton;

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@property (nonatomic,strong) NSString *randomNumber;//本地随机生成的验证码

@end

@implementation TDResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *titleStr = @"RESET_PASSWORD_TITLE";
    self.titleViewLabel.text = NSLocalizedString(titleStr, nil);
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
            [self sendResetPasswordCheckNum];
            
        } else if ([baseTool isValidateEmail:self.accountTextField.text]) {//邮箱有效
            [self resetPasswordByEmail];
            
        } else {
            [self.activityView stopAnimating];
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"INPUT_ERROR", nil)
                                                                    message:NSLocalizedString(@"ENTER_RIGHT_PHONE_OR_EMAIL", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
        }
    }
}

#pragma mark  - 手机重置密码--发送验证码请求
- (void)sendResetPasswordCheckNum {
    
    int num = (arc4random() % 1000000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];
    self.randomNumber = randomNumber;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *message = [NSString stringWithFormat:@"您正在重置密码，验证码为%@，5分钟内有效，请勿泄露。",self.randomNumber];
    params[@"msg"] = message;
    params[@"mobile"] = self.accountTextField.text;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/send_captcha_message_for_reset_password/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [responseObject writeToFile:@"/Users/Eliteu/Desktop/pli/ta.plist" atomically:YES];
        NSDictionary *dict = responseObject;
        id code = dict[@"code"];
        
        if ([code integerValue] == 200) {
            TDPhoneSendNumResetViewController *phoneVC = [[TDPhoneSendNumResetViewController alloc] init];
            phoneVC.phoneStr = self.accountTextField.text;
            phoneVC.randomNumber = randomNumber;
            [self.navigationController pushViewController:phoneVC animated:YES];
            
        }else if ([code intValue] == 403){//手机没注册
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:@""
                                                                    message:NSLocalizedString(@"PHONE_NUMBER_NOT_REGISTER", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
            
            
        } else {
            [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"RESET_FAILED", nil)
                                                                    message:NSLocalizedString(@"RESET_FAILED", nil)
                                                           onViewController:self.navigationController.view
                                                                 shouldHide:YES];
        }
        [self.activityView stopAnimating];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%ld",(long)error.code);
        [self.activityView stopAnimating];
    }];
}

#pragma mark - 重置邮箱账号密码
- (void)resetPasswordByEmail {
    
    [OEXAuthentication resetPasswordWithEmailId:self.accountTextField.text completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
            
            [[OEXFlowErrorViewController sharedInstance] animationUp];
            
            if(!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if(httpResp.statusCode == 200) {
                    
                    NSDictionary *dataDic = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                    NSLog(@"重置密码 ++++++++ %@",dataDic);
                    
                    if ([dataDic[@"success"] intValue] == 0) {
                        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorTitle]
                                                                                message:dataDic[@"value"]
                                                                       onViewController:self.navigationController.view
                                                                             shouldHide:YES];
                    } else {
                        
                        TDEmailResetViewController *emailRegisterVc = [[TDEmailResetViewController alloc] init];
                        emailRegisterVc.acountStr = self.accountTextField.text;
                        [self.navigationController pushViewController:emailRegisterVc animated:YES];
                    }
                    
                    
                } else if(httpResp.statusCode <= 400 && httpResp.statusCode < 500) {
                    
                    NSDictionary *dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                    NSString *responseStr = [[dictionary objectForKey:@"email"] firstObject];
                    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorTitle]
                                                                            message:responseStr
                                                                   onViewController:self.navigationController.view
                                                                         shouldHide:YES];
                    
                } else if(httpResp.statusCode > 500) {
                    
                    NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorTitle]
                                                                            message:responseStr
                                                                   onViewController:self.navigationController.view
                                                                         shouldHide:YES];
                }
                
            } else {
                
                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings floatingErrorTitle]
                                                                        message:[error localizedDescription]
                                                               onViewController:self.navigationController.view
                                                                     shouldHide:YES];
            }
            
        });
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
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.messageLabel.text = NSLocalizedString(@"PHONE_OR_EMAIL_RESET_PASSWORD", nil);
    [self.view addSubview:self.messageLabel];
    
    self.accountTextField = [[UITextField alloc] init];
    self.accountTextField.placeholder = NSLocalizedString(@"PHONE_OR_EMAIL", nil);
    self.accountTextField.textColor = [UIColor colorWithHexString:colorHexStr10];
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
    self.bottomButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.bottomButton.titleLabel.numberOfLines = 0;
    self.bottomButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    [self.bottomButton addTarget:self action:@selector(bottomButtonAtion:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomButton setAttributedTitle:[self setAttribute] forState:UIControlStateNormal];
    [self.view addSubview:self.bottomButton];
    self.bottomButton.hidden = YES;
    
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
