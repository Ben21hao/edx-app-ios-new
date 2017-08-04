//
//  TDSubCouponViewController.m
//  edX
//
//  Created by Ben on 2017/6/6.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDSubCouponViewController.h"
#import "TDCouponCell.h"
#import "TDCouponModel.h"
#import <MJExtension/MJExtension.h>
#import <MJRefresh/MJRefresh.h>

@interface TDSubCouponViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UILabel *noDataLabel;

@property (nonatomic,assign) NSInteger page;//页数
@property (nonatomic,strong) NSMutableArray *couponArray;

@property (nonatomic,strong) TDBaseToolModel *toolModel;

@property (nonatomic,strong) TDBaseView *loadingView;
@property (nonatomic,assign) BOOL isForgound;

@end

@implementation TDSubCouponViewController

- (NSMutableArray *)couponArray {
    if (!_couponArray) {
        _couponArray = [[NSMutableArray alloc] init];
    }
    return _couponArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *titleStr = NSLocalizedString(@"NO_USE_COUPON", nil);
    if (self.whereFrom == 2) {
        titleStr = NSLocalizedString(@"IS_USED_COUPON", nil);
    } else if (self.whereFrom == 3) {
        titleStr = NSLocalizedString(@"IS_OVERDUE_COUPON", nil);
    }
    self.title = titleStr;
    
    self.toolModel = [[TDBaseToolModel alloc] init];
    self.page = 1;
    
    [self setViewConStraint];
    
    self.isForgound = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exchangeHandle) name:@"TD_User_Coupon_Exchange_Sucess" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.isForgound) {
        self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
        [self.view addSubview:self.loadingView];
        
        [self requestCouponData:1];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.page = 1;
    self.isForgound = NO;
}

- (void)exchangeHandle {
    [self getNewData];
}

//下拉刷新
- (void)getNewData {
    self.page = 1;
    [self.tableView.mj_footer resetNoMoreData];//消除没有更多数据状态
    self.tableView.mj_footer.hidden = NO;
    
    [self requestCouponData:1];
}

//上拉加载
- (void)loadMoreData {
    self.page ++;
    [self requestCouponData:2];
}

#pragma mark - 数据
- (void)requestCouponData:(NSInteger)type {
    
    if (![self.toolModel networkingState]) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[@"username"] = self.username;
    dic[@"status"] = @(self.whereFrom);
    dic[@"pageindex"] = @(self.page);
    dic[@"pagesize"] = @8;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.tableView.mj_header endRefreshing];//结束刷新
        [self.tableView.mj_footer endRefreshing];
        [self.loadingView removeFromSuperview];
        
        if (self.page == 1) {
            [self.couponArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        int code = [responseDic[@"code"] intValue];
        
        if (code == 200) {
            NSDictionary *dataDic = responseDic[@"data"];
            
            NSArray *couponListArray = dataDic[@"coupons_list"];
            if (couponListArray.count > 0) {
                
                for (NSDictionary *couponDic in couponListArray) {
                    TDCouponModel *model = [TDCouponModel mj_objectWithKeyValues:couponDic];
                    if (model) {
                        model.status = dataDic[@"status"];
                        if (self.whereFrom != 1) {
                            model.signStr = self.title;
                        }
                        [self.couponArray addObject:model];
                    }
                }
                [self.tableView reloadData];
                
                self.noDataLabel.hidden = YES;
                if (self.couponArray.count < 8) {
                    [self hideTableFooterView];
                }
                
            } else {
                if (self.page == 1) {
                    [self judgeNumOfCoupons:0];
                }
            }
        } else if (code == 204) { //没有更多数据
            
            self.page --;
            [self hideTableFooterView];
            
            [self.view makeToast:NSLocalizedString(@"NO_MORE_DATA", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else if (code == 404) {
            [self judgeNumOfCoupons:0];
            
        } else {
            [self judgeNumOfCoupons:1];
            
            [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
        NSLog(@"--->> %d --->> %@",code,responseDic[@"msg"]);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self judgeNumOfCoupons:1];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"优惠券 error---- %@",error);
    }];
}

- (void)hideTableFooterView {
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
    self.tableView.mj_footer.hidden = YES;
}

- (void)judgeNumOfCoupons:(NSInteger)type {
    
    if (self.couponArray.count == 0) {//数组为0时
        
        [self hideTableFooterView];
        
        NSString *warmingStr = NSLocalizedString(@"NO_AVALIDE_COUPON", nil);
        if (self.whereFrom == 2) {
            warmingStr = NSLocalizedString(@"NO_USED_COUPON", nil);
        } else if (self.whereFrom == 3) {
            warmingStr = NSLocalizedString(@"NO_EXPIRED_COUPON", nil);
        }
        
        if (type == 0) {
           [self.view makeToast:warmingStr duration:1.08 position:CSToastPositionCenter];
        }
        
        self.noDataLabel.hidden = NO;
        self.noDataLabel.text = warmingStr;
    }
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.couponArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDCouponModel *model = self.couponArray[indexPath.row];
    
    TDCouponCell *cell = [[TDCouponCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDCouponCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.couponModel = model;
    
    WS(weakSelf);
    cell.showDetailHandle = ^(BOOL isSelected){
        model.isSelected = isSelected;
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    };
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDCouponModel *model = self.couponArray[indexPath.row];
    return model.isSelected ? 198 : 168;
}

#pragma mark - UI
- (void)setViewConStraint {
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-8);
    }];
    
    self.noDataLabel = [[UILabel alloc] init];
    self.noDataLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.noDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.tableView addSubview:self.noDataLabel];
    
    [self.noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.tableView);
    }];
    
    self.noDataLabel.hidden = YES;
    [self setUpRefreshView];
}

- (void)setUpRefreshView {
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewData)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    self.tableView.mj_footer.automaticallyHidden = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
