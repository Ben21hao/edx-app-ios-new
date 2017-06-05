//
//  UserFirstViewController.m
//  edX
//
//  Created by Elite Edu on 16/8/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "UserFirstViewController.h"
#import "UserCouponItem.h"
#import <MJExtension/MJExtension.h>
#import <AFNetworking.h>
#import "OEXUserDetails.h"
#import <MJRefresh/MJRefresh.h>
#import "UIColor+JHHexColor.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"

@interface UserFirstViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *couponTableView;
@property (weak,nonatomic) IBOutlet UIView *loadV;//加载状态view
@property (weak,nonatomic) IBOutlet UILabel *diconnectNet;//断开网络文本

@property (nonatomic,strong) UserCouponItem *userModel;
@property (nonatomic,strong) NSMutableArray *coupArr;
@property (nonatomic,copy) NSString *type;//type
@property (nonatomic,strong) AFHTTPSessionManager *manager;
@property (nonatomic,assign) BOOL reachable; //是否有网
@property (nonatomic,assign) int count; //优惠券张数
@property (nonatomic,assign) NSInteger page; //当前页数
@property (nonatomic,assign) NSInteger maxPages;
@property (nonatomic,strong) UIView *view0;
@property (nonatomic,strong) UILabel *noDataLabel;

@end

@implementation UserFirstViewController

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
    
    self.title = NSLocalizedString(@"NO_USE_COUPON", nil);
    
    [self.couponTableView registerNib:[UINib nibWithNibName:@"UserCouponTableViewCell" bundle:nil] forCellReuseIdentifier:@"couponCell"];
    [self.couponTableView registerNib:[UINib nibWithNibName:@"UserDiscountTableViewCell" bundle:nil] forCellReuseIdentifier:@"discountCell"];
    self.couponTableView.separatorStyle = NO;
    
    [self getNewData];//请求数据
    [self setUpRefreshView];//上下拉刷新
   
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.loadV.hidden = NO;
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate]; //网络情况
    self.reachable = [appD.reachability isReachable];
    if (!_reachable) {
        _diconnectNet.hidden = NO;
        self.loadV.hidden = YES;
    }
}
- (void)setUpRefreshView{
    self.couponTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(getNewData)];
    self.couponTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    self.couponTableView.mj_footer.automaticallyHidden = YES;

}

#pragma mark - 加载更多数据
- (void)loadMoreData{
    
    [_manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @1;
    params[@"pageindex"] = @(self.page);
    params[@"pagesize"] = @5;
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    
    [_manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([responseObject[@"code"] intValue] == 204) {
           
        } else if ([responseObject[@"code"] intValue] == 200){
            NSMutableArray *arr = [UserCouponItem mj_objectArrayWithKeyValuesArray:responseObject[@"data"][@"coupons_list"]];
            [_coupArr addObjectsFromArray:arr];
            
            self.userModel.pagesize = [responseObject[@"pages"] integerValue];//总页数
            [self.couponTableView reloadData];
            self.page++;
        }
        
        if (self.page > self.maxPages) {
            [self.couponTableView.mj_footer endRefreshingWithNoMoreData];
        }else{
            [self.couponTableView.mj_footer endRefreshing];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error--%@",error);
    }];
}

//请求数据
- (void)getNewData {
    
    [self.couponTableView.mj_footer resetNoMoreData];//消除没有更多数据状态
    self.couponTableView.mj_footer.hidden = NO;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    self.page = 1;
    _manager = manager;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @1;
    params[@"pageindex"] = @(self.page);
    params[@"pagesize"] = @5;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.couponTableView.mj_header endRefreshing];//结束刷新
        self.coupArr = [UserCouponItem mj_objectArrayWithKeyValuesArray:responseObject[@"data"][@"coupons_list"]];
        self.maxPages = [responseObject[@"data"][@"pages"] integerValue];

        [self.couponTableView reloadData];
        if (self.coupArr.count == 0) {
            [self hasNoCouponView];
        } else {
            [self haveYou];//有优惠券
            self.noDataLabel.hidden = YES;
        }
        self.loadV.hidden = YES;//加载完成后隐藏加载状态view
        self.page++;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error--%@",error);
    }];
}

- (void)hasNoCouponView {
    self.noDataLabel = [[UILabel alloc] init];
    self.noDataLabel.text = NSLocalizedString(@"NO_AVALIDE_COUPON", nil);
    self.noDataLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.noDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [self.couponTableView  addSubview:self.noDataLabel];
    
    [self.noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.couponTableView.mas_centerX);
        make.centerY.mas_equalTo(self.couponTableView.mas_centerY).offset(-18);
    }];
}

- (void)haveYou{
    if (self.coupArr.count > 8) {
        self.couponTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
        self.couponTableView.mj_footer.automaticallyHidden = YES;
    }
    if (_view0.superview) {
        [_view0 removeFromSuperview];
    } else{
        NSLog(@"没有父控件");
    }
}

#pragma mark --UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.coupArr.count;
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
    item.status = 1;
    cell.UserCouponItem = item;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSString *str1 = @"#F6BB42";
    NSString *str2 = @"#FFFAED";
    if ([item.coupon_type isEqualToString:@"满减券"]) {
        
    }else if ([item.coupon_type isEqualToString:@"折扣券"]) {
        str1 = colorHexStr1;
        str2 = @"#EDFAFF";
        
    } else {
        str1 = @"#95CD5B";
        str2 = @"#EBF6DF";
    }
    
    cell.topV.backgroundColor = [UIColor colorWithHexString:str1];
    cell.detailButton.backgroundColor = [UIColor colorWithHexString:str1];
    cell.bottomV.backgroundColor = [UIColor colorWithHexString:str2];
    cell.detailView.backgroundColor = [UIColor colorWithHexString:str2];
    
    WS(weakSelf);
    cell.showDetailHandle = ^(BOOL isSelected){
        item.isSelected = isSelected;
        [weakSelf.couponTableView reloadData];
    };
    
    return  cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    UserCouponItem *item =  self.coupArr[indexPath.section];
    if (item.isSelected == YES) {
        return 208;
    } else {
       return 160;
    }

}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 8;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end


