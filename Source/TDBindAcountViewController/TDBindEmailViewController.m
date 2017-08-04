//
//  TDBindEmailViewController.m
//  edX
//
//  Created by Elite Edu on 17/1/5.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDBindEmailViewController.h"
#import "TDBindSuccessViewController.h"
#import "TDBaseToolModel.h"

@interface TDBindEmailViewController ()

@property (nonatomic,strong) UITextField *emailTextField;
@property (nonatomic,strong) UIButton *handinButton;
@property (nonatomic,strong) TDBaseToolModel *baseTool;

@end

@implementation TDBindEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"BIND_EMAIL", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.baseTool = [[TDBaseToolModel alloc] init];
}

#pragma mark - 提交
- (void)handinButtonAcion:(UIButton *)sender {
    [self.emailTextField resignFirstResponder];
    
    if (![self.baseTool networkingState]) {
        return;
        
    } else if (self.emailTextField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"EMAIL_ADDRESS_PROMPT", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if ([self.baseTool isValidateEmail:self.emailTextField.text]) {
        [self handinToService];
        
    } else {
        [self.view makeToast:NSLocalizedString(@"EMAIL_FORMAT_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
    }
}

- (void)handinToService { 
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.username forKey:@"username"];
    [params setValue:self.emailTextField.text forKey:@"email"];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/bind_email/",ELITEU_URL];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *respondDic = (NSDictionary *)responseObject;
        id code = respondDic[@"code"];
        
        if ([code intValue] == 200) {
            if (self.bindEmailHandle) {
                self.bindEmailHandle(self.emailTextField.text);
            }
            TDBindSuccessViewController *successVC = [[TDBindSuccessViewController alloc] init];
            [self.navigationController pushViewController:successVC animated:YES];
            
//        } else if ([code intValue] == 402) {
//            [self.view makeToast:NSLocalizedString(@"EMAIL_AREADY_SEND", nil) duration:1.08 position:CSToastPositionCenter];
            
        }  else if ([code intValue] == 500) {
            [self.view makeToast:NSLocalizedString(@"EMAIL_UNKNOWN_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else if ([code  intValue] == 403) {
            [self.view makeToast:NSLocalizedString(@"EMAIL_IS_REGISTERED", nil) duration:1.08 position:CSToastPositionCenter];
            
        }  else {
            NSLog(@"验证登录密码 -- %@",respondDic[@"msg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"验证登录密码 -- %ld",(long)error.code);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.emailTextField resignFirstResponder];
}

#pragma mark - UI
- (void)configView {
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.placeholder = NSLocalizedString(@"EMAIL_ADDRESS_PROMPT", nil);
    self.emailTextField.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.emailTextField.textColor = [UIColor colorWithHexString:colorHexStr9];
    self.emailTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.emailTextField];
    
    self.handinButton = [[UIButton alloc] init];
    self.handinButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.handinButton.layer.cornerRadius = 4.0;
    [self.handinButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
    [self.handinButton addTarget:self action:@selector(handinButtonAcion:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.handinButton];
}

- (void)setViewConstraint {
    [self.emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(39);
    }];
    
    [self.handinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.emailTextField.mas_bottom).offset(18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(39);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end



