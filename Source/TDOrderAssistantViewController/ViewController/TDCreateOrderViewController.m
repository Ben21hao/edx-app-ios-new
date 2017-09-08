//
//  TDCreateOrderViewController.m
//  edX
//
//  Created by Elite Edu on 17/3/1.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDCreateOrderViewController.h"
#import "TDOrderTeacherSuccessViewController.h"

#import "OEXAccessToken.h"
#import "OEXAuthentication.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#define unitPrice 12.50

@interface TDCreateOrderViewController () <UITableViewDelegate,UITableViewDataSource,UITextViewDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) TDBaseToolModel *baseTool;

@property (nonatomic,strong) UIView *headerView;
@property (nonatomic,strong) UILabel *holderLabel;
@property (nonatomic,strong) UITextView *inputView;
@property (nonatomic,strong) UIView *footerView;
@property (nonatomic,strong) UILabel *messageLabel;

@property (nonatomic,strong) NSString *timeStr;
@property (nonatomic,strong) NSString *iconStr;
@property (nonatomic,assign) float effectiveIcon;//可用宝典
@property (nonatomic,assign) BOOL isSuccess;
@property (nonatomic,assign) NSInteger failType;

@end

@implementation TDCreateOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"APPOINTMENT_DETAILS", nil);
    [self.rightButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
    WS(weakSelf);
    self.rightButtonHandle = ^(){
        [weakSelf.inputView resignFirstResponder];
        [weakSelf createOrderAction];
    };
    
    [self setviewConstraint];
    self.baseTool = [[TDBaseToolModel alloc] init];
    self.isSuccess = NO;
    
    [self getUserDetailMessage];
  
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeStr = [NSString stringWithFormat:@"%@ %@~%@",self.dateStr,self.starTimeStr,self.endTimeStr];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *startDate = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@:00",self.dateStr,self.starTimeStr]];
    NSDate *endDate = [formatter dateFromString:[NSString stringWithFormat:@"%@ %@:00",self.dateStr,self.endTimeStr]];
    NSTimeInterval timeInterval = [endDate timeIntervalSince1970] - [startDate timeIntervalSince1970];
    
    int minute = (int)timeInterval / 60;
    
    self.iconStr = [NSString stringWithFormat:@"%.2f",minute * unitPrice];
    NSLog(@"时间 -- %@ ---> %@ == %d ==> %@",startDate,endDate,minute,self.iconStr);
}

#pragma mark - 预约结果
- (void)gotoResultView {
    
    TDOrderTeacherSuccessViewController *successVC = [[TDOrderTeacherSuccessViewController alloc] init];
    successVC.whereFrom = self.whereFrom;
    successVC.isSuccess = self.isSuccess;
    successVC.quetionStr = self.inputView.text;
    successVC.iconStr = self.iconStr;
    successVC.timeStr = self.timeStr;
    successVC.failType = self.failType;
    successVC.username = self.username;
    [self.navigationController pushViewController:successVC animated:YES];

}

#pragma mark - 获取用户详细信息
- (void)getUserDetailMessage {
    if (![self.baseTool networkingState]) {
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/user/v1/accounts/%@",ELITEU_URL,self.username];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer]; // 返回的格式 JSON
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", nil];// 可接受的文本参数规格
    manager.requestSerializer = [AFJSONRequestSerializer serializer]; //先讲请求设置为json
    [manager.requestSerializer setValue:@"application/merge-patch+json" forHTTPHeaderField:@"Content-Type"];// 开始设置请求头
    
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [manager.requestSerializer setValue:authValue forHTTPHeaderField:@"Authorization"];//安全验证
    
    [manager PATCH:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *remainScore = [NSString stringWithFormat:@"%@",responseObject[@"remainscore"]];
        self.effectiveIcon = [remainScore floatValue];
        
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"获取个人信息出错 -- %ld, %@",(long)error.code, error.userInfo[@"com.alamofire.serialization.response.error.data"]);
    }];
}

#pragma mrk - 创建订单
- (void)createOrderAction {
    
    if (![self.baseTool networkingState]) {
        return;
    }
    
    [SVProgressHUD showWithStatus:@"正在预约..."];
    SVProgressHUD.defaultMaskType = SVProgressHUDMaskTypeBlack;
    SVProgressHUD.defaultStyle = SVProgressHUDAnimationTypeNative;
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.assistantName forKey:@"assistant_username"];
    [dic setValue:self.courseId forKey:@"course_id"];
    [dic setValue:self.dateStr forKey:@"service_date"];
    [dic setValue:[NSString stringWithFormat:@"%@ %@:00",self.dateStr,self.starTimeStr] forKey:@"service_begin_at"];
    [dic setValue:[NSString stringWithFormat:@"%@ %@:00",self.dateStr,self.endTimeStr] forKey:@"service_end_at"];
    [dic setValue:self.inputView.text forKey:@"question"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/generate_order/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"助教时间 --- %@",responseObject);
        [SVProgressHUD dismiss];
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        NSInteger codeType = [code integerValue];
        if (codeType == 200) {
            self.isSuccess = YES;
            
        } else {
            self.isSuccess = NO;
            self.failType = codeType;
        }
        [self gotoResultView];
        NSLog(@"预约信息 -- %@ ----- %@",code,responseDic[@"msg"]);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"预约助教出错 --- %ld",(long)error.code);
    }];
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr7];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDCreateOrderCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TDCreateOrderCell"];
    }
    cell.userInteractionEnabled = NO;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    cell.detailTextLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.detailTextLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"PAYMENT_STANDARD", nil);
            cell.detailTextLabel.attributedText = [self.baseTool setDetailString:[NSString stringWithFormat:@"%.2f%@",unitPrice,NSLocalizedString(@"COINTS_MIN", nil)] withFont:14 withColorStr:colorHexStr9];
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"RESERCED_PERIOD", nil);
            cell.detailTextLabel.text = self.timeStr;
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"PREPAID_COIS", nil);
            cell.detailTextLabel.attributedText = [self.baseTool setDetailString:[NSString stringWithFormat:@"%@%@",self.iconStr,NSLocalizedString(@"COINS_VALUE", nil)] withFont:14 withColorStr:colorHexStr9];
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"AVAILABLE_COINS", nil);
            cell.detailTextLabel.attributedText = [self.baseTool setDetailString:[NSString stringWithFormat:@"%.2f%@",self.effectiveIcon,NSLocalizedString(@"COINS_VALUE", nil)] withFont:14 withColorStr:colorHexStr9];
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark - textViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        self.holderLabel.hidden = NO;
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.holderLabel.hidden = YES;
    return YES;
}

#pragma mark - UI
- (void)setviewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(self.view);
    }];
    
    self.tableView.tableHeaderView = [self setTableViewHeaderView];
    self.tableView.tableFooterView  = [self settableViewFooterView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)tapAction {
    [self.inputView resignFirstResponder];
}

- (UIView *)setTableViewHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 158)];
    self.headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [self setLabelConstraint:NSLocalizedString(@"QUETIONS_DESCRIPTION", nil)];
    [self.headerView addSubview:titleLabel];
    
    self.inputView = [[UITextView alloc] init];
    self.inputView.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.inputView.layer.masksToBounds = YES;
    self.inputView.layer.cornerRadius = 4.0;
    self.inputView.layer.borderWidth = 0.5;
    self.inputView.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    self.inputView.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.inputView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.inputView.delegate = self;
    [self.headerView addSubview:self.inputView];
    
    self.holderLabel = [self setLabelConstraint:NSLocalizedString(@"TYPE_QUETIONS", nil)];
    self.holderLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.headerView addSubview:self.holderLabel];
    
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [self.headerView addSubview:line];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(15);
        make.top.mas_equalTo(self.headerView.mas_top).offset(11);
        make.height.mas_equalTo(21);
    }];
    
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(3);
        make.left.mas_equalTo(self.headerView.mas_left).offset(15);
        make.right.mas_equalTo(self.headerView.mas_right).offset(-15);
        make.height.mas_equalTo(98);
    }];
    
    [self.holderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.inputView.mas_left).offset(8);
        make.top.mas_equalTo(self.inputView.mas_top).offset(8);
    }];
    
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(15);
        make.bottom.mas_equalTo(self.headerView.mas_bottom).offset(0);
        make.right.mas_equalTo(self.headerView.mas_right).offset(0);
        make.height.mas_equalTo(0.5);
    }];
        
    return self.headerView;
}

- (UILabel *)setLabelConstraint:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:14];
    label.textColor = [UIColor colorWithHexString:colorHexStr10];
    label.text = title;
    return label;
}

- (UIView *)settableViewFooterView {
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 39)];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.text = NSLocalizedString(@"NOTE_COINS", nil);
    [self.footerView addSubview:self.messageLabel];
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.footerView.mas_centerX);
        make.centerY.mas_equalTo(self.footerView.mas_centerY);
    }];
    return self.footerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
