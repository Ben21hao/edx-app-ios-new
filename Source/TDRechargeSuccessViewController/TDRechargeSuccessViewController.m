//
//  TDRechargeSuccessViewController.m
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDRechargeSuccessViewController.h"
#import "SuccessRechargeModel.h"
#import <MJExtension/MJExtension.h>
#import "TDBaseView.h"

@interface TDRechargeSuccessViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) SuccessRechargeModel *successModel;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) NSInteger timeNum;

@end

@implementation TDRechargeSuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"RECHARGE_SUCCESS", nil);
    [self setLoadDataView];
    
    [self requerestData];
    [self setViewConstraint];
    
    self.timeNum = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(repeatAction) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self timerIndivalde];
}

- (void)repeatAction {
    
    self.timeNum++;
    
    [self requerestDataRepeatAction];
    
    if (self.timeNum > 5) {
        [self timerIndivalde];
    }
}

- (void)timerIndivalde {
    [self.loadIngView removeFromSuperview];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)requerestDataRepeatAction {
    
    if (self.successModel != nil) {
        [self timerIndivalde];
        return;
    }
    if (self.timeNum > 5) {
        [self timerIndivalde];
        return;
    }
    [self requerestData];
}

- (void)backButtonAction:(UIButton *)sender {
    if (self.successModel == nil) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 请求数据
- (void)requerestData {
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.orderId forKey:@"coin_record_id"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/finance/coin_record_status/",ELITEU_URL];
    
    WS(weakSelf);
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"%@",responseObject);
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        
        if ([code intValue] == 200) {
            
            NSDictionary *dataDic = responDic[@"data"];
            weakSelf.successModel = [SuccessRechargeModel mj_objectWithKeyValues:dataDic];
            
            if (self.updateTotalCoinHandle) {
                self.updateTotalCoinHandle(weakSelf.successModel.remain_coin);
            }
            [weakSelf.tableView reloadData];
            
            [self.loadIngView removeFromSuperview];
            
        } else {
            //            [self.view makeToast:responDic[@"msg"] duration:1.08 position:CSToastPositionCenter];
            NSLog(@"error -- %@",responDic[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self.loadIngView removeFromSuperview];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        
        NSLog(@"error -- %@",error);
    }];
    
}

- (NSAttributedString *)setData:(NSString *)amountStr {
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    return  [baseTool setDetailString:amountStr withFont:14 withColorStr:colorHexStr8];
}

#pragma mark - tableview Delegate 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rechargeSuccessCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"rechargeSuccessCell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"RECHARGE_MONEY", nil);
            cell.detailTextLabel.attributedText = [self setData:[NSString stringWithFormat:@"￥%.2f",[self.successModel.amount floatValue]]];
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"RECHARGE_BAODIAN", nil);
            cell.detailTextLabel.attributedText = [self setData:[NSString stringWithFormat:@"%.2f%@",[self.successModel.total_coin floatValue],NSLocalizedString(@"COINS_VALUE", nil)]];
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"AVALIABLE_BAODIAN", nil);
            cell.detailTextLabel.attributedText = [self setData:[NSString stringWithFormat:@"%.2f%@",[self.successModel.remain_coin floatValue],NSLocalizedString(@"COINS_VALUE", nil)]];
            break;
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

#pragma mark - UI
- (void)setViewConstraint {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 128)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UIButton *successButton = [[UIButton alloc] init];
    [successButton setImage:[UIImage imageNamed:@"success"] forState:UIControlStateNormal];
    [successButton setTitle:NSLocalizedString(@"RECHARGE_SUCCESS", nil) forState:UIControlStateNormal];
    [successButton setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
    successButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    successButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    successButton.contentEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    [headerView addSubview:successButton];
    
    [successButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.mas_equalTo(headerView);
        make.size.mas_equalTo(CGSizeMake(228, 80));
    }];
    
    UIView *titleView = [[TDBaseView alloc] initWithTitle:NSLocalizedString(@"RECHARGE_MESSAGE", nil)];
    titleView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [headerView addSubview:titleView];
    
    [titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(headerView);
        make.top.mas_equalTo(successButton.mas_bottom).offset(0);
        make.height.mas_equalTo(48);
    }];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    self.tableView.tableHeaderView = headerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
