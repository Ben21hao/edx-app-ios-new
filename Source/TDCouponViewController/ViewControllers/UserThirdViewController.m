//
//  UserThirdViewController.m
//  edX
//
//  Created by Elite Edu on 16/8/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "UserThirdViewController.h"
#import "UserCouponItem.h"
#import <MJExtension/MJExtension.h>
#import <AFNetworking.h>
#import "UIColor+JHHexColor.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"
#import <MJRefresh/MJRefresh.h>

#define JHScreenW [UIScreen mainScreen].bounds.size.width
#define JHScreenH [UIScreen mainScreen].bounds.size.height
@interface UserThirdViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *contentTableView;
@property (nonatomic,strong) UserCouponItem *userModel;
//model
@property (nonatomic,strong) NSMutableArray *coupArr;
//加载view
@property (weak, nonatomic) IBOutlet UIView *loadV;
//没有优惠券View
@property (weak, nonatomic) IBOutlet UILabel *nothingL;
@property (weak, nonatomic) IBOutlet UILabel *netDisconnect;
//是否有网
@property (nonatomic, assign) BOOL reachable;
//当前页数
@property (nonatomic,assign) NSInteger page;
@property (nonatomic,assign) NSInteger maxPages;
@property (nonatomic,strong) UILabel *noDataLabel;

@end

@implementation UserThirdViewController
//懒加载
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
    self.title = NSLocalizedString(@"IS_OVERDUE_COUPON", nil);
    [_contentTableView registerNib:[UINib nibWithNibName:@"UserCouponTableViewCell" bundle:nil] forCellReuseIdentifier:@"couponCell"];
    [_contentTableView registerNib:[UINib nibWithNibName:@"UserDiscountTableViewCell" bundle:nil] forCellReuseIdentifier:@"discountCell"];
    //请求数据
    [self getNewData];
    self.contentTableView.separatorStyle = NO;
    self.contentTableView.backgroundColor = [UIColor colorWithRed:247 green:249 blue:251 alpha:1.0];
    //上下拉刷新
    [self setUpRefreshView];
    self.loadV.hidden = YES;
    self.nothingL.hidden = YES;
    self.netDisconnect.hidden = YES;
    [self.contentTableView.mj_footer resetNoMoreData];
    
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

#pragma mark - request Data
- (void)loadMoreData{
   
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @3;
    params[@"pageindex"] = @(_page);
    params[@"pagesize"] = @5;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            
            NSArray *listArr = responseObject[@"data"][@"coupons_list"];
            if (listArr.count > 0) {
                for (int i = 0; i < listArr.count; i ++) {
                    UserCouponItem *item = [UserCouponItem mj_objectWithKeyValues:listArr[i]];
                    [self.coupArr addObject:item];
                    NSLog(@"++++++%@",item.coupon_name);
                }
            }
            
            self.userModel.pagesize = [responseObject[@"pages"] integerValue];//总页数
            [self.contentTableView reloadData];
            
        } else {
            NSLog(@"%@",responDic[@"msg"]);
        }
        
        _page ++;
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

- (void)getNewData{
    [self.contentTableView.mj_footer resetNoMoreData];//消除没有更多数据状态
    self.contentTableView.mj_footer.hidden = NO;

    self.page = 1;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];//会话管理者
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"status"] = @3;
    params[@"pageindex"] = @(_page);
    params[@"pagesize"] = @5;
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/market/user_coupons/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.contentTableView.mj_header endRefreshing];//结束刷新
        
        if (self.coupArr == nil ) {
            self.coupArr = [[NSMutableArray alloc] init];
        }
        
        if (self.page == 1 && self.coupArr.count > 0) {
            [self.coupArr removeAllObjects];
        }
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            
            NSArray *listArr = responseObject[@"data"][@"coupons_list"];
            if (listArr.count > 0) {
                for (int i = 0; i < listArr.count; i ++) {
                    UserCouponItem *item = [UserCouponItem mj_objectWithKeyValues:listArr[i]];
                    [self.coupArr addObject:item];
                    NSLog(@"------%@",item.coupon_name);
                }
            }
            _maxPages = [responseObject[@"data"][@"pages"] integerValue];
            [self.contentTableView reloadData];
            
            
        } else {
            NSLog(@"%@",responDic[@"msg"]);
        }
        
        if (self.coupArr.count == 0) {
            [self hasNoCouponView];
        } else {
            self.noDataLabel.hidden = YES;
        }
        //加载完成后隐藏加载状态view
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
    self.noDataLabel.text =  NSLocalizedString(@"NO_EXPIRED_COUPON", nil);
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
    
    UserCouponItem *item =  self.coupArr[indexPath.section];
    item.status = 3;
    cell.UserCouponItem = item;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.topV.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    cell.bottomV.backgroundColor = [UIColor colorWithHexString:colorHexStr5];

    cell.waterV.hidden = YES;
    cell.outTime.hidden = NO;
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
}

@end
