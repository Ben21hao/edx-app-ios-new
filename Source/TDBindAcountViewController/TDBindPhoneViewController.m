//
//  TDBindPhoneViewController.m
//  edX
//
//  Created by Elite Edu on 17/1/5.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDBindPhoneViewController.h"
#import "TDBaseToolModel.h"
#import <MJExtension/MJExtension.h>
#import "OEXAccessToken.h"
#import "OEXAuthentication.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

@interface TDBindPhoneViewController ()

@property (nonatomic,strong) UITextField *phoneTextField;
@property (nonatomic,strong) UITextField *codeTextField;
@property (nonatomic,strong) UIButton *codeButton;
@property (nonatomic,strong) UIButton *handinButton;

@property (nonatomic,strong) NSString *phoneStr;
@property (nonatomic,strong) NSString *randomNumber;

@property (nonatomic,assign) int timeNum;
@property (nonatomic,strong) NSTimer *timer;//定时器

@property (nonatomic,strong) TDBaseToolModel *baseTool;

@end

@implementation TDBindPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"PHONE_DINDING", nil);
    
    [self configView];
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.baseTool = [[TDBaseToolModel alloc] init];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.timer invalidate];
}

#pragma mark - 获取验证码
- (void)codeButtonAction:(UIButton *)sender {
    [self resignTextFieldFirstResponder];
    
    if (![self.baseTool networkingState]) {
        return;
        
    } else if (self.phoneTextField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"PHONE_IS_EMPTY", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if ([self.baseTool isValidateMobile:self.phoneTextField.text]) {
        [self cutDownTime];
        [self getCodeFromService];
        
    } else {
        [self.view makeToast:NSLocalizedString(@"PHONE_FORMAT_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
    }
}

- (void)getCodeFromService {
    
        int num = (arc4random() % 1000000);
    NSString *randomNumber = [NSString stringWithFormat:@"%.6d", num];//六位数验证码
    self.randomNumber = randomNumber;
    NSString *message = [NSString stringWithFormat:@"您正在绑定英荔账号，验证码为%@，5分钟内有效。",randomNumber];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.phoneTextField.text forKey:@"mobile"];
    [params setValue:message forKey:@"msg"];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/check_mobile_is_bind/",ELITEU_URL];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *respondDic = (NSDictionary *)responseObject;
        id code = respondDic[@"code"];
        
        if ([code intValue] == 200) {
            self.phoneStr = self.phoneTextField.text;
            [self.view makeToast:NSLocalizedString(@"MESSAGE_AREADY_SEND", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else if ([code intValue] == 403) {
            [self.timer invalidate];
            self.codeButton.userInteractionEnabled = YES;
            [self.view makeToast:NSLocalizedString(@"PHONE_IS_REGISTERED", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else {
            [self.timer invalidate];
            self.codeButton.userInteractionEnabled = YES;
            NSLog(@"验证登录密码 -- %@",respondDic[@"msg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.timer invalidate];
        self.codeButton.userInteractionEnabled = YES;
        NSLog(@"验证登录密码 -- %ld",(long)error.code);
    }];
    
}

#pragma mark -- 倒计时
- (void)cutDownTime {
    self.codeButton.userInteractionEnabled = NO;
    self.timeNum = 60;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timeChange {
    self.codeButton.userInteractionEnabled = NO;
    self.timeNum -= 1;
    [self.codeButton setTitle:[NSString stringWithFormat:@"%d%@",self.timeNum,NSLocalizedString(@"SECOND", nil)] forState:UIControlStateNormal];
    if (self.timeNum <= 0) {
        [self.timer invalidate];
        self.codeButton.userInteractionEnabled = YES;
        [self.codeButton setTitle:NSLocalizedString(@"RESEND", nil) forState:UIControlStateNormal];
    }
}


#pragma mark - 提交
- (void)handinButtonAction:(UIButton *)sender {
    
    [self resignTextFieldFirstResponder];
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    
    if (![self.baseTool networkingState]) {
        return;
        
    } else if (![baseTool isValidateMobile:self.phoneTextField.text]) {
        [self.view makeToast:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if (self.phoneTextField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"PHONE_IS_EMPTY", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if (self.codeTextField.text.length == 0) {
        [self.view makeToast:NSLocalizedString(@"VERIFICATION_CODE_IS_EMPTY", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if (![self.codeTextField.text isEqualToString:self.randomNumber]) {
        [self.view makeToast:NSLocalizedString(@"VERIFICATION_CODE_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if (![self.phoneTextField.text isEqualToString:self.phoneStr] && [baseTool isValidateMobile:self.phoneTextField.text]) {//已获取验证码，然后再修改了手机
        [self.view makeToast:NSLocalizedString(@"STILL_NO_GET_VERI", nil) duration:1.08 position:CSToastPositionCenter];
        
    } else if ([self.phoneTextField.text isEqualToString:self.phoneStr] && [baseTool isValidateMobile:self.phoneTextField.text]) {
        [self handinToService];
        
    } else {
        [self.view makeToast:NSLocalizedString(@"ENTER_CORRECT_NUMBER", nil) duration:1.08 position:CSToastPositionCenter];
    }
}

- (void)handinToService {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.phoneTextField.text forKey:@"mobile"];
    NSString *url = [NSString stringWithFormat:@"%@/api/user/v1/accounts/%@",ELITEU_URL,self.username];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer]; // 返回的格式 JSON
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", nil];// 可接受的文本参数规格
     manager.requestSerializer = [AFJSONRequestSerializer serializer]; //先讲请求设置为json
    [manager.requestSerializer setValue:@"application/merge-patch+json" forHTTPHeaderField:@"Content-Type"];// 开始设置请求头
    
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [manager.requestSerializer setValue:authValue forHTTPHeaderField:@"Authorization"];//安全验证
    
    [manager PATCH:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *respondDic = (NSDictionary *)responseObject;
        NSString *mobile = respondDic[@"mobile"];
        if ([mobile isEqualToString:self.phoneStr]) {
            if (self.bindPhoneHandle) {
                self.bindPhoneHandle(self.phoneTextField.text);
            }
            [self.view makeToast:NSLocalizedString(@"PHONE_BIND_SUCCESS", nil) duration:1.08 position:CSToastPositionCenter];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popToViewController:self.navigationController.childViewControllers[1] animated:YES];
            });
        } else {
            [self.view makeToast:NSLocalizedString(@"PHONE_BIND_FAIL", nilh) duration:1.08 position:CSToastPositionCenter];
            NSLog(@"更新失败 -- %ld",(long)respondDic[@"msg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"绑定出错 -- %ld, %@",(long)error.code, error.userInfo[@"com.alamofire.serialization.response.error.data"]);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self resignTextFieldFirstResponder];
}

- (void)resignTextFieldFirstResponder {
    [self.codeTextField resignFirstResponder];
    [self.phoneTextField resignFirstResponder];
}

#pragma mark - UI
- (void)configView {
    
    self.phoneTextField = [self setTextFieldWithTitle:NSLocalizedString(@"PLEASE_ENTER_PHONE_NUMBER", nil)];
    [self.view addSubview:self.phoneTextField];
    
    self.codeTextField = [self setTextFieldWithTitle:NSLocalizedString(@"PLEASE_ENTER_VERI", nil)];
    [self.view addSubview:self.codeTextField];

    self.codeButton = [self setButtonWithTitle:NSLocalizedString(@"GET_VERIFICATION", nil) font:13];
    [self.codeButton addTarget:self action:@selector(codeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.codeButton];
    
    self.handinButton = [self setButtonWithTitle:NSLocalizedString(@"SUBMIT", nil) font:16];
    [self.handinButton addTarget:self action:@selector(handinButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.handinButton];
    
}

- (void)setViewConstraint {
    
    [self.phoneTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(39);
    }];
    
    [self.codeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.phoneTextField.mas_bottom).offset(8);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.size.mas_equalTo(CGSizeMake(89, 39));
    }];
    
    [self.codeTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.codeButton.mas_top);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.codeButton.mas_left).offset(-6);
        make.height.mas_equalTo(39);
    }];
    
    [self.handinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.codeTextField.mas_bottom).offset(18);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(39);
    }];
   
}

- (UITextField *)setTextFieldWithTitle:(NSString *)title {
    UITextField *textField = [[UITextField alloc] init];
    textField.placeholder = title;
    textField.font = [UIFont fontWithName:@"OpenSans" size:14];
    textField.textColor = [UIColor colorWithHexString:colorHexStr9];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.layer.cornerRadius = 4.0;
    return  textField;
}

- (UIButton *)setButtonWithTitle:(NSString *)title font:(NSInteger)size {
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    button.layer.cornerRadius = 4.0;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:size];
    return button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


