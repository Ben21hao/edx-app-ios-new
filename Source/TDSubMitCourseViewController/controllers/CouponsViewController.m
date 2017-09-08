//
//  CouponsViewController.m
//  edX
//
//  Created by Elite Edu on 16/10/14.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "CouponsViewController.h"
#import <MJExtension/MJExtension.h>
#import <AFNetworking.h>
#import "OEXUserDetails.h"
#import <MJRefresh/MJRefresh.h>
#import "UIColor+JHHexColor.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"
#import "CouponsNameTableViewCell.h"

@interface CouponsViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) UILabel *noDataLabel;
@property (nonatomic,strong) NSMutableArray *couponArray;

@end

static NSString *ID = @"cell";

@implementation CouponsViewController

- (NSMutableArray *)couponArray {
    if (!_couponArray) {
        _couponArray = [[NSMutableArray alloc] init];
        CouponsNameItem *model = [[CouponsNameItem alloc] init];
        model.coupon_name =NSLocalizedString(@"SELECT_COUPON", nil);
        [_couponArray addObject:model];
    }
    return _couponArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.titleViewLabel.text = NSLocalizedString(@"COUPON_PAPER", nil);
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.scrollEnabled = NO;
    
    [self requestNewData];
    [self setNoDataViewConstraint];
    [self setLoadDataView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - 没优惠券
- (void)setNoDataViewConstraint {
    
    self.noDataLabel = [[UILabel alloc] init];
    self.noDataLabel.center = self.view.center;
    self.noDataLabel.text = NSLocalizedString(@"NO_CHOOSE_COUPON", nil);
    self.noDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.noDataLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.noDataLabel];
    [self.noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
    }];
    self.noDataLabel.hidden = YES;
}

#pragma mark - requestData
- (void)requestNewData {

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"apply_amount"] = @(_apply_amount);
    [params setValue:self.courseIds forKey:@"course_ids"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/get_user_coupon_info/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.loadIngView removeFromSuperview];
        
        if (self.couponArray == nil) {
            self.couponArray = [[NSMutableArray alloc] init];
        }
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            NSArray *listArr = responDic[@"data"][@"coupon_list"];
            if (listArr.count > 0) {
                for (int i = 0; i < listArr.count; i ++) {
                    CouponsNameItem *item = [CouponsNameItem mj_objectWithKeyValues:listArr[i]];
                    if (item) {
                        [self.couponArray addObject:item];
                    }
                }
                [self.tableView reloadData];
            }
        } else {
            NSLog(@"%@",responDic[@"msg"]);
        }
        if (self.couponArray.count == 1) {
            self.noDataLabel.hidden = NO;
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        [self.loadIngView removeFromSuperview];
        
        NSLog(@"error--%@",error);
    }];
}


#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.couponArray.count == 1 ? 0 : self.couponArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    CouponsNameItem *model = self.couponArray[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CouponCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CouponCell"];
    }
    cell.textLabel.text = model.coupon_name;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    
    if ([model.coupon_issue_id isEqualToString:self.selectCouponId]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CouponsNameItem *model = self.couponArray[indexPath.row];
    if (self.selectCouponHandle) {
        self.selectCouponHandle(model);
    }
    [self.navigationController popViewControllerAnimated:YES];
    
//    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
