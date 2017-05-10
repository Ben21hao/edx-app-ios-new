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
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.acountStr forKey:@"email"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/resend_active_email/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.activityView stopAnimating];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        [self.view makeToast:dict[@"msg"] duration:1.08 position:CSToastPositionCenter];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.activityView stopAnimating];
        NSLog(@"重发邮件 -- %ld",(long)error.code);
    }];
}

- (void)backButtonAction:(UIButton *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI
- (void)configView {
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.text = [Strings hadSendEmailWithCount:self.acountStr];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    [self.view addSubview:self.messageLabel];
    
    self.loginButton = [[UIButton alloc] init];
    self.loginButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.loginButton.layer.masksToBounds = YES;
    self.loginButton.layer.cornerRadius = 4.0;
    [self.loginButton setTitle:NSLocalizedString(@"ACTIVITY_LOGIN", nil) forState:UIControlStateNormal];
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
