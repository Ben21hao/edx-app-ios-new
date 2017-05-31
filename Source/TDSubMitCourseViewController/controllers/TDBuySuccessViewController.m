//
//  TDBuySuccessViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/13.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDBuySuccessViewController.h"
#import "Reachability.h"

#import "edX-Swift.h"
#import "OEXRouter.h"
#import "TDBaseToolModel.h"

@interface TDBuySuccessViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSDictionary *dataDic;

@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) NSInteger timeNum;

@end

@implementation TDBuySuccessViewController

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView = [[UITableView alloc] init];
        _tableView.tableFooterView = [[UIView alloc] init];
        _tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setViewConstraint];
    [self requestData];
    
    [self setLoadDataView];
    
    self.timeNum = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(repeatAction) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"ADD_SUCCESS", nil);
    [self.rightButton setTitle:NSLocalizedString(@"GO_TO_STUDY", nil) forState:UIControlStateNormal];
    self.rightButton.titleLabel.font = [UIFont systemFontOfSize:16];
    WS(weakSelf);
    self.rightButtonHandle = ^(){
        [weakSelf gotoStudy];
    };
    [self.leftButton addTarget:self action:@selector(popAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self timerIndivalde];
}

#pragma mark - 去学习
- (void)gotoStudy {
     [[OEXRouter sharedRouter] showMyCoursesAnimated:YES pushingCourseWithID:nil];
}

#pragma mark - 返回
- (void)popAction:(UIButton *)sender {
     [[OEXRouter sharedRouter] showMyCoursesAnimated:YES pushingCourseWithID:nil];
}

#pragma mark - 数据
- (void)requestData {
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.orderId forKey:@"order_id"];
    
    NSLog(@"订单号 --->>> %@ ==========  %@",self.orderId,dic);
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/get_order_status/",ELITEU_URL];
    
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            self.dataDic = [NSDictionary dictionaryWithDictionary:responDic[@"data"]];
            [self.tableView reloadData];
            
        } else {
            
        }
        NSLog(@"----- 支付成功 ----- %@",responDic);
        
        [self.loadIngView removeFromSuperview];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadIngView removeFromSuperview];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@" error -------%@",error);
    }];
}

- (void)repeatAction {
    
    self.timeNum++;
    
    [self requerestDataRepeatAction];
    
    if (self.timeNum > 5) {
        [self timerIndivalde];
    }
}

- (void)requerestDataRepeatAction {
    
    if (self.dataDic != nil) {
        [self timerIndivalde];
        return;
    }
    if (self.timeNum > 5) {
        [self timerIndivalde];
        return;
    }
    [self requestData];
}

- (void)timerIndivalde {
    [self.loadIngView removeFromSuperview];
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataDic[@"give_coin"] floatValue] > 0 ? 7 : 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BuySuccessCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"BuySuccessCell"];
    }
    cell.userInteractionEnabled = NO;
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    
    cell.detailTextLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"COURSE_TITLE", nil);
            NSString *courStr = self.dataDic[@"course_display_names"];
            cell.detailTextLabel.text = courStr;
        }
            break;
        case 1: {
            cell.textLabel.text = NSLocalizedString(@"ORIGIN_PRICE", nil);
            float oringin = [self.dataDic[@"total_amount"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"￥%.2f",oringin] withFont:14 withColorStr:colorHexStr8];
        }
            break;
        case 2: {
            cell.textLabel.text = NSLocalizedString(@"CUT_ACTIVITY", nil);
            float activity = [self.dataDic[@"activate_amount"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"-￥%.2f",activity] withFont:14 withColorStr:colorHexStr8];
        }
            break;
        case 3: {
            cell.textLabel.text = NSLocalizedString(@"CUT_COUPON", nil);
            float coupon = [self.dataDic[@"coupon_amount"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"-￥%.2f",coupon] withFont:14 withColorStr:colorHexStr8];
        }
            break;
        case 4: {
            cell.textLabel.text = NSLocalizedString(@"CUT_BAODIAN", nil);
            float baodian = [self.dataDic[@"cost_amount"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"-￥%.2f",baodian] withFont:14 withColorStr:colorHexStr8];
        }
            break;
        case 5: {
            cell.textLabel.text = NSLocalizedString(@"PAY_LAST", nil);
            float pay = [self.dataDic[@"real_amount"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"￥%.2f",pay] withFont:14 withColorStr:colorHexStr8];
        }
            break;
        case 6: {
            cell.textLabel.text = NSLocalizedString(@"COIN_RECEIVE", nil);
            float pay = [self.dataDic[@"give_coin"] floatValue];
            cell.detailTextLabel.attributedText = [baseTool setDetailString:[NSString  stringWithFormat:@"%.2f%@",pay,NSLocalizedString(@"COINS_VALUE", nil)] withFont:14 withColorStr:colorHexStr8];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    UILabel *titelLabel = [[UILabel alloc] init];
    titelLabel.font = [UIFont systemFontOfSize:14];
    titelLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    titelLabel.textAlignment = NSTextAlignmentCenter;
    titelLabel.text = [NSString stringWithFormat:@"——————— %@ ———————",NSLocalizedString(@"COURSE_MESSAGE",nil)];
    [headerView addSubview:titelLabel];
    
    [titelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(headerView.mas_centerX);
        make.centerY.mas_equalTo(headerView.mas_centerY);
    }];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 58;
}


#pragma mark - UI
- (void)setViewConstraint {

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 68)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UIButton *successButton = [[UIButton alloc] init];
    [successButton setImage:[UIImage imageNamed:@"success"] forState:UIControlStateNormal];
    successButton.contentEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    
    [successButton setTitle:NSLocalizedString(@"ADD_COURSE_SUCCESS", nil) forState:UIControlStateNormal];
    successButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [successButton setTitleColor:[UIColor colorWithHexString:colorHexStr10] forState:UIControlStateNormal];
    successButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [headerView addSubview:successButton];
    
    [successButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(headerView.mas_centerY);
        make.centerX.mas_equalTo(headerView.mas_centerX);
    }];
    
    self.tableView.tableHeaderView = headerView;
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
