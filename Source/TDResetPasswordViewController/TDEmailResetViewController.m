//
//  TDEmailResetViewController.m
//  edX
//
//  Created by Ben on 2017/5/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDEmailResetViewController.h"
#import "TDBaseToolModel.h"
#import "edX-Swift.h"
#import "OEXAuthentication.h"

@interface TDEmailResetViewController () <UIGestureRecognizerDelegate>

@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UIButton *loginButton;
@property (nonatomic,strong) UIButton *resendButton;

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@end

@implementation TDEmailResetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setViewConstraint];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [backButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"RESET_BY_EMAIL", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

#pragma mark - 去登录
- (void)loginButtonAction:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - 重新发送邮件
- (void)resendButtonAction:(UIButton *)sender {
    [self.activityView startAnimating];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        return;
    }
    
    
    [self resetPasswordByEmail];
    
}

#pragma mark - 重置邮箱账号密码
- (void)resetPasswordByEmail {
    
    [OEXAuthentication resetPasswordWithEmailId:self.acountStr completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityView stopAnimating];
            
            [[OEXFlowErrorViewController sharedInstance] animationUp];
            
            if(!error) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
                if(httpResp.statusCode == 200) {
                    
                    NSDictionary *dataDic = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                    NSLog(@"重置密码 ++++++++ %@",dataDic);
                    
                    if ([dataDic[@"success"] intValue] == 0) {
                        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                                message:dataDic[@"value"]
                                                                       onViewController:self.navigationController.view
                                                                             shouldHide:YES];
                    } else {
                        
                        [self.view makeToast:NSLocalizedString(@"CLICK_RESEND_SUCCESS", nil) duration:1.08 position:CSToastPositionCenter];
                    }
                    
                    
                } else if(httpResp.statusCode >= 400 && httpResp.statusCode < 500) {
                    
                    NSDictionary *dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                    NSString *responseStr = [[dictionary objectForKey:@"email"] firstObject];
                    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                            message:responseStr
                                                                   onViewController:self.navigationController.view
                                                                         shouldHide:YES];
                    
                } else if(httpResp.statusCode > 500) {
                    
                    NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                            message:responseStr
                                                                   onViewController:self.navigationController.view
                                                                         shouldHide:YES];
                }
                
            } else {
                
                [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"FLOATING_ERROR_TITLE", nil)
                                                                        message:[error localizedDescription]
                                                               onViewController:self.navigationController.view
                                                                     shouldHide:YES];
            }
            
        });
    }];
}

- (void)backButtonAction:(UIButton *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI
- (void)configView {
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.text = [Strings hadSendResetEmailWithCount:self.acountStr];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    [self.view addSubview:self.messageLabel];
    
    self.loginButton = [[UIButton alloc] init];
    self.loginButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.loginButton.layer.masksToBounds = YES;
    self.loginButton.layer.cornerRadius = 4.0;
    [self.loginButton setTitle:NSLocalizedString(@"RESETED_LOGIN", nil) forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    [self.loginButton addTarget:self action:@selector(loginButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.resendButton = [[UIButton alloc] init];
    self.resendButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    [self.resendButton addTarget:self action:@selector(resendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.resendButton setAttributedTitle:[self setAttribute] forState:UIControlStateNormal];
    [self.view addSubview:self.resendButton];
    
    
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
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(41);
    }];
    
    [self.resendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(41);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.loginButton.mas_centerY);
        make.right.mas_equalTo(self.loginButton.mas_right).offset(-8);
    }];
}

- (NSMutableAttributedString *)setAttribute {
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"NO_RECEIVE_EMAIL", nil) attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr8]}];
    
    NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"CLICK_RESEND", nil) attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr1]}];
    [str1 appendAttributedString:str2];
    return str1;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
