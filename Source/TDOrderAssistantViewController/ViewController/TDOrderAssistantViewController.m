//
//  TDOrderAssistantViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDOrderAssistantViewController.h"
#import "TDTeacherDetailViewController.h"
#import "TDTeacherTimesViewController.h"
#import "TDTalkOrderViewController.h"

#import "TDOrderAssitantCell.h"

#import "TDTeacherModel.h"

#import <MJRefresh/MJRefresh.h>
#import <MJExtension/MJExtension.h>

@interface TDOrderAssistantViewController () <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) NSInteger page;

@property (nonatomic,strong) NSMutableArray *teacherArray;

@property (nonatomic,strong) UILabel *nullLabel;
@property (nonatomic,strong) TDBaseView *loadingView;

@end

@implementation TDOrderAssistantViewController

- (NSMutableArray *)teacherArray {
    if (!_teacherArray) {
        _teacherArray = [[NSMutableArray alloc] init];
    }
    return _teacherArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"TEACH_ASSISTANT", nil);
    
    [self setViewConstraint];
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    
    self.page = 1;
    [self requestData:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

#pragma mark - 下拉刷新
- (void)pullDownRefresh {
    self.page = 1;
    [self requestData:1];
}

#pragma mark - 上拉加载
- (void)topPullLoading {
    self.page ++;
    [self requestData:2];
}

#pragma mark - requestData
/*
 type:
 1 ： 下拉刷新或初次进来加载数据
 2 ： 上拉加载更多数据
 */
- (void)requestData:(NSInteger)type {
    
    
    if (![self.baseTool networkingState]) {
        self.loadingView.hidden = YES;
        if (self.teacherArray.count == 0) {
            self.nullLabel.hidden = NO;
        }
        return;
    }
    
    if (self.page == 1) {
        self.tableView.mj_footer.hidden = NO;
        [self.tableView.mj_footer resetNoMoreData];
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.courseId forKey:@"course_id"];
    [dic setValue:@(self.page) forKey:@"pageindex"];
    [dic setValue:@"8" forKey:@"pagesize"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistants/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self.loadingView.hidden = YES;
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        
        if (self.page == 1 && self.teacherArray.count != 0) {
            [self.teacherArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            
            NSArray *dataArray = responseDic[@"data"];
            if (dataArray.count > 0) {
                for (int i = 0; i < dataArray.count; i ++) {
                    TDTeacherModel *model = [TDTeacherModel mj_objectWithKeyValues:dataArray[i]];
                    if (model) {
                        [self.teacherArray addObject:model];
                    }
                }
                if (self.teacherArray.count > 0) {
                    [self.tableView reloadData];
                } else {
                    self.nullLabel.hidden = NO;
                }
            }
            
            if (dataArray.count < 8) {
                [self hiddenFooterView];
            }
            
        } else if ([code intValue] == 201) { //没有更多数据了
            
            self.page --;
            [self hiddenFooterView];
            [self.view makeToast:NSLocalizedString(@"NO_MORE_DATA", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else if ([code intValue] == 404) { //该课程暂无助教
            self.nullLabel.hidden = NO;
            [self.view makeToast:NSLocalizedString(@"CURRENTLY_NO_TA", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
        self.loadingView.hidden = YES;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self.loadingView.hidden = YES;
        self.nullLabel.hidden = NO;
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"获取助教列表出错 -- %ld",(long)error.code);
    }];
}

- (void)hiddenFooterView {
    self.tableView.mj_footer.hidden = YES;
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
}

- (void)setNullData {
    self.nullLabel = [[UILabel alloc] init];
    self.nullLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.nullLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.nullLabel.text = NSLocalizedString(@"CURRENTLY_NO_TA", nil);
    [self.view addSubview:self.nullLabel];
    
    [self.nullLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.centerY.mas_equalTo(self.view.mas_centerY).offset(-30);
    }];
    
    self.nullLabel.hidden = YES;
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.teacherArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TDTeacherModel *model = self.teacherArray[indexPath.row];
    
    TDOrderAssitantCell *cell = [[TDOrderAssitantCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"orderAssitantCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.model = model;
    
    WS(weakSelf);
    cell.headerHandle = ^(){//头像
        [weakSelf gotoOrderDetail:model];
    };
    cell.orderButtonHandle = ^(){//预约
        [weakSelf gotoTeacherSchedule:model.username];
    };
    cell.talkButtonHandle = ^(){//即时服务
        [weakSelf gotoClassRoom:model.username indexpath:indexPath];
    };
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 98;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TDTeacherModel *model = self.teacherArray[indexPath.row];
    [self gotoOrderDetail:model];
}


#pragma mark - 详情
- (void)gotoOrderDetail:(TDTeacherModel *)model {
    
    TDTeacherDetailViewController *detailVC = [[TDTeacherDetailViewController alloc] init];
    detailVC.model = model;
    detailVC.myName = self.myName;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - 预约
- (void)gotoTeacherSchedule:(NSString *)username {
    
    TDTeacherTimesViewController *timesVc = [[TDTeacherTimesViewController alloc] init];
    timesVc.whereFrom = self.whereFrom;
    timesVc.assistantName = username;
    timesVc.username = self.myName;
    timesVc.courseId = self.courseId;
    [self.navigationController pushViewController:timesVc animated:YES];
}

#pragma mark - 即时服务
- (void)gotoClassRoom:(NSString *)assitantName indexpath:(NSIndexPath *)indexpath {
    
    if (![self.baseTool networkingState]) {
        return;
    }

    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/realtime_status/%@",ELITEU_URL,assitantName];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"查询助教状态 --- %@",responseObject);
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            
            NSString *status = responseDic[@"data"][@"realtime_status"];
            if ([status intValue] == 1) {//离线(0)，空闲(1)，忙碌(2)
                [self gotoTalkOrder:assitantName];
                
            } else if ([status intValue] == 0) {
                [self reloadData:indexpath status:status];
                [self.view makeToast:NSLocalizedString(@"TA_OFFLINE", nil) duration:1.08 position:CSToastPositionCenter];
            } else {
                [self reloadData:indexpath status:status];
                [self.view makeToast:NSLocalizedString(@"TA_BUSY", nil) duration:1.08 position:CSToastPositionCenter];
            }
            
        } else {
            [self.view makeToast:NSLocalizedString(@"SYSTEM_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
        NSLog(@"查询助教状态 --- %@%@",code ,responseDic[@"msg"]);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"查询助教状态出错 -- %ld",(long)error.code);
    }];
}

- (void)reloadData:(NSIndexPath *)indexPath status:(NSString *)status {
    TDTeacherModel *model = self.teacherArray[indexPath.row];
    model.realtime_status = status;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gotoTalkOrder:(NSString *)assitantName {
    TDTalkOrderViewController *talkVC = [[TDTalkOrderViewController alloc] init];
    talkVC.username = self.myName;
    talkVC.assistantName = assitantName;
    talkVC.courseId = self.courseId;
    WS(weakSelf);
    talkVC.appointmentSuccessHandle = ^{
        [weakSelf pullDownRefresh];
    };
    [self.navigationController pushViewController:talkVC animated:YES];
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(topPullLoading)];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(pullDownRefresh)];
    self.tableView.mj_footer.automaticallyHidden = YES;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
    [self.view addSubview:self.loadingView];
    
    [self setNullData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
