//
//  UserSecondViewController.m
//  edX
//
//  Created by Elite Edu on 16/8/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "UserSecondViewController.h"
#import "UserCouponItem.h"
#import <MJExtension/MJExtension.h>
#import <AFNetworking.h>
#import "UIColor+JHHexColor.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"
#import <MJRefresh/MJRefresh.h>

@interface UserSecondViewController () <UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (weak, nonatomic) IBOutlet UIView *loadV;//加载view
@property (weak, nonatomic) IBOutlet UILabel *netDisconnect;

@property (nonatomic,strong) UserCouponItem *userModel;
@property (nonatomic,strong) NSMutableArray *coupArr;
@property (nonatomic,assign) BOOL reachable;//是否有网
@property (nonatomic,strong) AFHTTPSessionManager *manager;
@property (nonatomic,assign) NSInteger page;//当前页数
@property (nonatomic,assign) NSInteger maxPages;
@property (nonatomic,strong) UILabel *noDataLabel;

@end

@implementation UserSecondViewController
- (UserCouponItem *)userModel{
    if (_userModel == nil) {
        _userModel = [[UserCouponItem alloc] init];
    }
    return _userModel;
}
- (NSMutableArray *)coupArr{
    if (_coupArr == nil) {
        _coupArr = [NSMutableArray array];
    }
    return _coupArr;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"IS_USED_COUPON", nil);
    
    [_contentTableView registerNib:[UINib nibWithNibName:@"UserCouponTableViewCell" bundle:nil] forCellReuseIdentifier:@"couponCell"];
    [_contentTableView registerNib:[UINib nibWithNibName:@"UserDiscountTableViewCell" bundle:nil] forCellReuseIdentifier:@"discountCell"];
    
    [self getNewData];//请求数据
    self.contentTableView.separatorStyle = NO;
    self.contentTableView.backgroundColor = [UIColor colorWithRed:247 green:249 blue:251 alpha:1.0];
    
    [self setUpRefreshView];//上下拉刷新
    self.loadV.hidden = YES;
    self.netDisconnect.hidden = YES;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.loadV.hidden = NO;
    //网络情况
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];
    if (!_reachable) {
        _netDisconnect.hidden = NO;
        self.loadV.hidden = YES;
    }
}
- (void)setUpRefreshView{
    self.contentTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewData)];
    self.contentTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    self.contentTableView.mj_footer.automaticallyHidden = YES;
}

#pragma mark - 加载更多数据
- (void)loadMoreData{
    [_manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @2;
    params[@"pageindex"] = @(_page);
    params[@"pagesize"] = @5;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [_manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSMutableArray *arr = [UserCouponItem mj_objectArrayWithKeyValuesArray:responseObject[@"data"][@"coupons_list"]];
        [_coupArr addObjectsFromArray:arr];
        //总页数
        _userModel.pagesize = [responseObject[@"pages"] integerValue];
        [self.contentTableView reloadData];
        _page++;
        if (_page > _maxPages) {
            [self.contentTableView.mj_footer endRefreshingWithNoMoreData];
        }else{
            [self.contentTableView.mj_footer endRefreshing];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}
//请求数据
- (void)getNewData{
    //消除没有更多数据状态
    [self.contentTableView.mj_footer resetNoMoreData];
    self.contentTableView.mj_footer.hidden = NO;
    //会话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    _page = 1;
    _manager = manager;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @2;
    params[@"pageindex"] = @(_page);
    params[@"pagesize"] = @5;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success2--%@",responseObject);
        
        [self.contentTableView.mj_header endRefreshing]; //结束刷新
        
        self.coupArr = [UserCouponItem mj_objectArrayWithKeyValuesArray:responseObject[@"data"][@"coupons_list"]];
        self.maxPages = [responseObject[@"data"][@"pages"] integerValue];
        [self.contentTableView reloadData];
        
        if (self.coupArr.count == 0) {
            [self hasNoCouponView];
        } else {
            self.noDataLabel.hidden = YES;
        }
        self.loadV.hidden = YES;
        self.loadV.alpha = 0;
        _page++;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}

- (void)hasNoCouponView {
    self.noDataLabel = [[UILabel alloc] init];
    self.noDataLabel.text = NSLocalizedString(@"NO_USED_COUPON", nil);
    self.noDataLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.noDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.contentTableView  addSubview:self.noDataLabel];
    
    [self.noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentTableView.mas_centerX);
        make.centerY.mas_equalTo(self.contentTableView.mas_centerY).offset(-18);
    }];
}


#pragma mark --UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    //是否隐藏底部
    self.contentTableView.mj_footer.hidden = _page > _maxPages;
    return _coupArr.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *couponCell = @"couponCell";
    
    UserCouponTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:couponCell];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:couponCell owner:self options:nil] lastObject];
    }
    
    UserCouponItem *item =  _coupArr[indexPath.section];
    item.status = 2;
    cell.UserCouponItem = item;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([item.coupon_type isEqualToString:@"满减券"]) {
        cell.topV.backgroundColor = [UIColor colorWithHexString:@"#F6BB42"];
        cell.bottomV.backgroundColor = [UIColor colorWithHexString:@"#FFFAED"];
        
    }else if ([item.coupon_type isEqualToString:@"折扣券"]) {
        cell.topV.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
        cell.bottomV.backgroundColor = [UIColor colorWithHexString:@"#EDFAFF"];
        
    } else {
        cell.topV.backgroundColor = [UIColor colorWithHexString:@"#95CD5B"];
        cell.bottomV.backgroundColor = [UIColor colorWithHexString:@"#EBF6DF"];
    }
    cell.waterV.hidden = NO;
    cell.usedL.hidden = NO;
    return  cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 160;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 8;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
                                           
@end
