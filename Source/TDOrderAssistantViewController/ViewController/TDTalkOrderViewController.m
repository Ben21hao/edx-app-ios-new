//
//  TDTalkOrderViewController.m
//  edX
//
//  Created by Elite Edu on 17/3/9.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTalkOrderViewController.h"
#import "TDTalkModel.h"
#import <MJExtension/MJExtension.h>

@interface TDTalkOrderViewController () <UITextViewDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) UITextView *inputView;
@property (nonatomic,strong) UILabel *holderLabel;
@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UILabel *numLabel;

@property (nonatomic,strong) TDTalkModel *model;
@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDTalkOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.toolModel = [[TDBaseToolModel alloc] init];
    self.titleViewLabel.text = NSLocalizedString(@"INIT_INSTANT", nil);
    [self.rightButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
    WS(weakSelf);
    self.rightButtonHandle = ^{
        [weakSelf.inputView resignFirstResponder];
        [weakSelf handinQuetion];
    };
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr13];
}

- (void)handinQuetion {

    TDBaseToolModel *toolModel = [[TDBaseToolModel alloc] init];
    if (![toolModel networkingState]) {
        return;
    }
    
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"classroom://?"]]) {//先判断是否安装classroom
        [self gotoDownloadClassrooms];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"正在提交..."];
    SVProgressHUD.defaultMaskType = SVProgressHUDMaskTypeBlack;
    SVProgressHUD.defaultStyle = SVProgressHUDAnimationTypeNative;
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.courseId forKey:@"course_id"];
    [dic setValue:self.assistantName forKey:@"assistant_username"];
    [dic setValue:self.inputView.text forKey:@"question"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/generate_real_time_order/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"即时服务 --- %@",responseObject);
        
        [SVProgressHUD dismiss];
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            NSDictionary *dataDic = responseDic[@"data"];
            self.model = [TDTalkModel mj_objectWithKeyValues:dataDic];
            
            if (self.model) {
                NSString *roomUrlStr = [NSString stringWithFormat:@"classroom://?password=%@&username=%@",self.model.student_join_password,self.username];
                NSURL *roomUrl = [NSURL URLWithString:roomUrlStr];
                
                if ([[UIApplication sharedApplication] canOpenURL:roomUrl]) {//调起全时
                    [[UIApplication sharedApplication] openURL:roomUrl];
                    
                    self.appointmentSuccessHandle();
                    [self.navigationController popViewControllerAnimated:YES];
                    
                } else {
                    [self gotoDownloadClassrooms];
                }
            }
        } else if ([code intValue] == 401) {//不能预约自己
            [self.view makeToast:NSLocalizedString(@"APPOINTMENT_SELF", nil) duration:1.08 position:CSToastPositionCenter];
        } else if ([code intValue] == 402) {//先加入课程
            [self.view makeToast:NSLocalizedString(@"ENROLL_COURSE_FIRST", nil) duration:1.08 position:CSToastPositionCenter];
        } else if ([code intValue] == 500) {
            [self.view makeToast:NSLocalizedString(@"UNABEL_INIT_INSTANT", nil) duration:1.08 position:CSToastPositionCenter];
        } else {
            [self.view makeToast:NSLocalizedString(@"UNABEL_INIT_INSTANT", nil) duration:1.08 position:CSToastPositionCenter];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"即时服务出错 -- %ld",(long)error.code);
    }];
}

- (void)gotoDownloadClassrooms {
    NSLog(@" --- 还没下载 ----");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"NOT_INSTALLED_CLASSROOM", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                              otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alertView show];
}

#pragma mark - alertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/cn/app/classrooms/id1098590902?l=zh&ls=1&mt=8"]];
    }
}

#pragma mark - textView Delegate
- (void)textViewDidChange:(UITextView *)textView {
    self.numLabel.text = [NSString stringWithFormat:@"%lu/100",(unsigned long)textView.text.length];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.holderLabel.hidden = YES;
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.holderLabel.hidden = NO;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.inputView resignFirstResponder];
}

#pragma mark - UI
- (void)setViewConstraint {
    
    UILabel *titleLabel = [self setLabelConstraint:NSLocalizedString(@"QUETIONS_DESCRIPTION", nil)];
    [self.view addSubview:titleLabel];
    
    self.numLabel = [self setLabelConstraint:@"0/100"];
    [self.view addSubview:self.numLabel];
    
    self.inputView = [[UITextView alloc] init];
    self.inputView.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.inputView.layer.masksToBounds = YES;
    self.inputView.layer.cornerRadius = 4.0;
    self.inputView.layer.borderWidth = 0.5;
    self.inputView.layer.borderColor = [UIColor colorWithHexString:colorHexStr7].CGColor;
    self.inputView.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.inputView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.inputView.delegate = self;
    [self.view addSubview:self.inputView];
    
    self.holderLabel = [self setLabelConstraint:NSLocalizedString(@"TYPE_QUETIONS", nil)];
    self.holderLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.view addSubview:self.holderLabel];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *str1 = [self.toolModel setDetailString:NSLocalizedString(@"PAYMENT_NOTE", nil) withFont:14 withColorStr:colorHexStr9];
    NSMutableAttributedString *str2 = [self.toolModel setDetailString:NSLocalizedString(@"PAYMENT_NOTE_LAST", nil) withFont:14 withColorStr:colorHexStr9];
    [str1 appendAttributedString:str2];
    self.messageLabel.attributedText = str1;
    self.messageLabel.numberOfLines = 0;
    [self.view addSubview:self.messageLabel];
    
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [self.view addSubview:line];
    
    UIView *line1 = [[UIView alloc] init];
    line1.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [self.view addSubview:line1];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(15);
        make.top.mas_equalTo(self.view.mas_top).offset(15);
    }];
    
    [self.numLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view.mas_right).offset(-15);
        make.top.mas_equalTo(self.view.mas_top).offset(15);
    }];
  
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(15);
        make.left.mas_equalTo(self.view.mas_left).offset(15);
        make.right.mas_equalTo(self.view.mas_right).offset(-15);
        make.height.mas_equalTo(98);
    }];
    
    [self.holderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.inputView.mas_left).offset(8);
        make.top.mas_equalTo(self.inputView.mas_top).offset(8);
    }];
    
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(15);
        make.right.mas_equalTo(self.view.mas_right).offset(-15);
        make.top.mas_equalTo(self.inputView.mas_bottom).offset(15);
        make.height.mas_equalTo(0.5);
    }];

    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(line.mas_bottom).offset(15);
        make.left.mas_equalTo(self.view.mas_left).offset(15);
        make.right.mas_equalTo(self.view.mas_right).offset(-15);
    }];
    
    [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(15);
        make.right.mas_equalTo(self.view.mas_right).offset(-15);
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(0.5);
    }];
}

- (UILabel *)setLabelConstraint:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:14];
    label.textColor = [UIColor colorWithHexString:colorHexStr10];
    label.text = title;
    return label;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
