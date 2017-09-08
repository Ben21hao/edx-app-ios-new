//
//  TDPasswordResetViewController.m
//  edX
//
//  Created by Ben on 2017/5/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDPasswordResetViewController.h"
#import "TDBaseToolModel.h"
#import "edX-Swift.h"

@interface TDPasswordResetViewController ()<UIAlertViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UILabel *topLabel;
@property (nonatomic,strong) UITextField *passwordTextField;
@property (nonatomic,strong) UIButton *handinButton;

@property (nonatomic,strong) UIButton *eyeButton;
@property (nonatomic,strong) UIView *bgView;

@property (nonatomic,strong) UIActivityIndicatorView *activityView;

@property (nonatomic,strong) UIButton *leftButton;

@end

@implementation TDPasswordResetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setLeftNavigationBar];
    
    [self configView];
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title =NSLocalizedString(@"RESET_BY_PHONE", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.passwordTextField resignFirstResponder];
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

#pragma mark - 提交
- (void)handinButtonAction:(UIButton *)sender {
    [self.passwordTextField resignFirstResponder];
    [self.activityView stopAnimating];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:self.navigationController.view
                                                             shouldHide:YES];
        return;
    }
    
    if (self.passwordTextField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"PLEASE_SET_PASSWORD", nil) duration:1.08 position:CSToastPositionCenter];
    }else if (self.passwordTextField.text.length < 6) {
        [self.view makeToast:NSLocalizedString(@"MORE_PASSWORD", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if (self.passwordTextField.text.length > 30) {
        [self.view makeToast:NSLocalizedString(@"LESS_PASSWORD", nil) duration:1.08 position:CSToastPositionCenter];
    } else {
        [self resetPhonePassWord];
    }
}

- (void)resetPhonePassWord {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mobile"] = self.acountStr;
    params[@"password"] = self.passwordTextField.text;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/reset_password_by_mobile/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [responseObject writeToFile:@"/Users/Eliteu/Desktop/pli/aa.plist" atomically:YES];
        NSDictionary *dict = responseObject;
        NSString *code = dict[@"code"];
        long CODE = code.integerValue;
        
        if (CODE == 200) {//请求成功
            
            UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_PASSWORD_SUCCESS", nil)
                                                                   message:NSLocalizedString(@"MOBILE_PHONE_ACCOUNT_RESET_SUCCESS", nil)
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                         otherButtonTitles:nil, nil];
            successAlert.tag = 100;
            [successAlert show];
            
        } else { //请求失败
            UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_THE_PASSWORD_FAILED", nil)
                                                                message:NSLocalizedString(@"MOBILE_PHONE_ACCOUNT_RESET_FAILED", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil, nil];
            [failAlert show];
        };
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"密码重置 ---  %ld",(long)error.code);
    }];
}


#pragma mark - alertView Dlegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) {
        [self.passwordTextField resignFirstResponder];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

#pragma mark - 密码明文或暗文
- (void)eyeButtonAction:(UIButton *)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    if (self.passwordTextField.secureTextEntry == YES) {
        [self.eyeButton setTitle:@"\U0000f070" forState:UIControlStateNormal];
    } else {
        [self.eyeButton setTitle:@"\U0000f06e" forState:UIControlStateNormal];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.passwordTextField resignFirstResponder];
}


#pragma mark - ui
- (void)configView {
    self.topLabel = [[UILabel alloc] init];
    self.topLabel.text = NSLocalizedString(@"SET_PASSWORD", nil);
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.topLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.view addSubview:self.topLabel];
    
    self.bgView = [[UIView alloc] init];
    self.bgView.layer.masksToBounds = YES;
    self.bgView.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    self.bgView.layer.borderWidth = 1.0;
    self.bgView.layer.cornerRadius = 4.0;
    self.bgView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bgView];
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.placeholder = NSLocalizedString(@"PASSWORD_NUM", nil);
    self.passwordTextField.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.passwordTextField.textColor = [UIColor colorWithHexString:colorHexStr10];
    [self.bgView addSubview:self.passwordTextField];
    
    self.eyeButton = [[UIButton alloc] init];
    self.eyeButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:20];
    self.eyeButton.contentMode = UIViewContentModeCenter;
    [self.eyeButton setTitle:@"\U0000f070" forState:UIControlStateNormal];
    [self.eyeButton setTitleColor:[UIColor colorWithHexString:colorHexStr8] forState:UIControlStateNormal];
    [self.eyeButton addTarget:self action:@selector(eyeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.eyeButton];
    
    self.handinButton = [[UIButton alloc] init];
    self.handinButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.handinButton.layer.cornerRadius = 4.0;
    [self.handinButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
    [self.handinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.handinButton addTarget:self action:@selector(handinButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.handinButton];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.view addSubview:self.activityView];
}

- (void)setViewConstraint {
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.top.mas_equalTo(self.view.mas_top).offset(18);
    }];
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.top.mas_equalTo(self.topLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(41);
    }];
    
    [self.passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(self.bgView);
        make.left.mas_equalTo(self.bgView.mas_left).offset(8);
        make.right.mas_equalTo(self.bgView).offset(-30);
    }];
    
    [self.eyeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.bgView.mas_centerY);
        make.right.mas_equalTo(self.bgView).offset(-4);
        make.size.mas_equalTo(CGSizeMake(30, 21));
    }];
    
    [self.handinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.top.mas_equalTo(self.bgView.mas_bottom).offset(18);
        make.height.mas_equalTo(41);
    }];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.handinButton.mas_centerY);
        make.right.mas_equalTo(self.handinButton.mas_right).offset(-8);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
