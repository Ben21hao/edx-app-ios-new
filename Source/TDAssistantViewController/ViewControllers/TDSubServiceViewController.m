//
//  TDSubServiceViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDSubServiceViewController.h"
#import "TDAssistantCell.h" //助教cell
#import "TDAssistantTopCell.h" //课程名称cell
#import "TDAssistantFootCell.h" //时间、按钮cell

#import "TDTeachOrderDetailViewController.h"
#import "TDOrderCommentViewController.h"
#import "TDVideoPlayerViewController.h"

#import "TDAssistantServiceModel.h"
#import "TDAssistantCommentTagModel.h"

#import <MJExtension/MJExtension.h>
#import <MJRefresh/MJRefresh.h>
#import <UIImageView+WebCache.h>

@interface TDSubServiceViewController () <UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate>

@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic,strong) NSMutableArray *tagsArray;
@property (nonatomic,assign) NSInteger page;

@property (nonatomic,strong) TDBaseToolModel *toolModel;

@property (nonatomic,strong) UILabel *nullLabel;
@property (nonatomic,strong) TDBaseView *loadingView;
@property (nonatomic,assign) BOOL isForgound;

@end

@implementation TDSubServiceViewController

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (NSMutableArray *)tagsArray {
    if (!_tagsArray) {
        _tagsArray = [[NSMutableArray alloc] init];
    }
    return _tagsArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.page = 1;
    self.toolModel = [[TDBaseToolModel alloc] init];
    self.tableView.scrollsToTop = NO;
    
    NSString *title = @"待服务";
    switch (self.whereFrom) {
        case TDAssistantFromOne:
            title = @"待服务";
            break;
        case TDAssistantFromTwo:
            title = @"已完成";
            break;
        case TDAssistantFromThree:
            title = @"已取消";
            break;
            
        default:
            break;
    }
    self.title = title;
    
     [self setViewConstraint];
    self.isForgound = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downRefreshData) name:@"Cancel_Order_Deal" object:nil];
//    NSLog(@"屏幕大小 ---%f; %f /n %f ; %f",self.view.bounds.size.width,self.view.bounds.size.height,TDWidth,TDHeight);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"页面 --- %ld",(long)self.whereFrom);
    
    if (self.isForgound) {
        self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
        [self.view addSubview:self.loadingView];
        
        switch (self.whereFrom) {
            case TDAssistantFromOne:
                [self requestOrderData:0];
                break;
            case TDAssistantFromTwo:
                [self requestFinishOrderData];
                break;
            case TDAssistantFromThree:
                [self requestOrderData:1];
                break;
                
            default:
                break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.page = 1;
    self.isForgound = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 数据发生变化，重新请求数据
- (void)dataHadChange {
    
    switch (self.whereFrom) {
        case TDAssistantFromOne:
            [self requestOrderData:0];
            break;
        case TDAssistantFromTwo:
            [self requestFinishOrderData];
            break;
        case TDAssistantFromThree:
            [self requestOrderData:1];
            break;
        default:
            break;
    }
}

#pragma mark - 上拉加载
- (void)upLoadMoreData {
    [self dataHadChange];
}

#pragma mark - 下拉加载
- (void)downRefreshData {
    self.page = 1;
    [self dataHadChange];
}

#pragma mark - data 
/*type 待服务 0; 已取消 1*/
- (void)requestOrderData:(NSInteger)type {
    
    if (![self.toolModel networkingState]) {
        self.tableView.mj_header.hidden = YES;
        [self showNullData];
        self.loadingView.hidden = YES;
        return;
    }
    
    if (self.page == 1) {
        [self.tableView.mj_footer resetNoMoreData];
    }
    self.tableView.mj_header.hidden = NO;
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:type == 0 ? @"1" : @"-1" forKey:@"status"];/* status 待服务 1; 已取消 -1*/
    [dic setValue:@"10" forKey:@"pagesize"];
    [dic setValue:@(self.page) forKey:@"pageindex"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistantserver/%@",ELITEU_URL,self.username];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"助教服务 -- %@",responseObject);
        
        if (self.page == 1) {
            [self.dataArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            NSArray *dataArray = responseDic[@"data"];
            
            if (dataArray.count > 0) {
                for (int i = 0; i < dataArray.count; i ++) {
                    
                    TDAssistantServiceModel *serviceModel = [TDAssistantServiceModel mj_objectWithKeyValues:dataArray[i]];
                    NSString *timeStr = [self dateFormatStart:serviceModel.service_begin_at end:serviceModel.service_end_at];
                    serviceModel.service_time = [NSString stringWithFormat:@"%@ %@",serviceModel.service_date,timeStr];
                    
                    if (serviceModel) {
                        [self.dataArray addObject:serviceModel];
                    }
                }
                [self.tableView reloadData];
                
                [self endTableviewRefreshing];
                if (self.dataArray.count < 8 && self.page == 1) {
                    self.tableView.mj_footer.hidden = YES;
                } else {
                    self.tableView.mj_footer.hidden = NO;
                }
                self.page ++;
                
            } else {
                [self noMoreDataHandle];
                self.page == 1 ? self.page = 1 : self.page --;
            }
        } else if ([code intValue] == 204) {
            [self.view makeToast:@"没有更多数据了" duration:1.08 position:CSToastPositionCenter];
            [self noMoreDataHandle];
            
        } else {
            [self endTableviewRefreshing];
            NSLog(@"助教服务数据请求错误 -- %@",code);
        }
        [self showNullData];
        self.loadingView.hidden = YES;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:@"网络连接出错" duration:1.08 position:CSToastPositionCenter];
        
        [self showNullData];
        self.loadingView.hidden = YES;
        
        NSLog(@"助教服务数据出错 -- %ld",(long)error.code);
    }];
}

/*已完成*/
- (void)requestFinishOrderData {
    
    if (![self.toolModel networkingState]) {
        self.tableView.mj_header.hidden = YES;
        [self showNullData];
        self.loadingView.hidden = YES;
        return;
    }
    
    if (self.page == 1) {
        [self.tableView.mj_footer resetNoMoreData];
    }
    self.tableView.mj_header.hidden = NO;
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:@"2" forKey:@"status"];/*已服务 2 */
    [dic setValue:@"10" forKey:@"pagesize"];
    [dic setValue:@(self.page) forKey:@"pageindex"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistantserverfinshed/%@",ELITEU_URL,self.username];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"已完成的助教服务 -- %@",responseObject);
        
        if (self.page == 1) {
            [self.dataArray removeAllObjects];
            [self.tagsArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            NSArray *dataArray = responseDic[@"data"];
            if (dataArray.count > 0) {
                for (int i = 0; i < dataArray.count; i ++) {
                    TDAssistantServiceModel *serviceModel = [TDAssistantServiceModel mj_objectWithKeyValues:dataArray[i]];
                    NSString *timeStr = [self dateFormatStart:serviceModel.service_begin_at end:serviceModel.service_end_at];
                    serviceModel.service_time = [NSString stringWithFormat:@"%@ %@",serviceModel.service_date,timeStr];
                    if (serviceModel) {
                        [self.dataArray addObject:serviceModel];
                    }
                }
                
                [self endTableviewRefreshing];
                if (self.dataArray.count < 8 && self.page == 1) {
                    self.tableView.mj_footer.hidden = YES;
                } else {
                    self.tableView.mj_footer.hidden = NO;
                }
                self.page ++;
                
            } else {
                [self noMoreDataHandle];
                self.page == 1 ? self.page = 1 : self.page --;
            }
            
            NSArray *tagArray = responseDic[@"extra_data"][@"comment_tags"];
            if (tagArray.count > 0) {
                for (int i = 0; i < tagArray.count; i ++) {
                    TDAssistantCommentTagModel *model = [TDAssistantCommentTagModel mj_objectWithKeyValues:tagArray[i]];
                    model.isSelected = NO;
                    if (model) {
                        [self.tagsArray addObject:model];
                    }
                }
            }
            [self.tableView reloadData];
            
        } else if ([code intValue] == 204) {
            [self.view makeToast:@"没有更多数据了" duration:1.08 position:CSToastPositionCenter];
            [self noMoreDataHandle];
            
        } else {
            [self endTableviewRefreshing];
            NSLog(@"已完成的助教服务数据请求错误 -- %@",code);
        }
        
        [self showNullData];
        self.loadingView.hidden = YES;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:@"网络连接出错" duration:1.08 position:CSToastPositionCenter];

        [self showNullData];
        self.loadingView.hidden = YES;
        
        NSLog(@"已完成的助教服务数据出错 -- %ld",(long)error.code);
    }];
}

- (void)showNullData {
    if (self.dataArray.count == 0) {
        self.nullLabel.hidden = NO;
        [self.tableView reloadData];
    }
}

- (void)endTableviewRefreshing {
    if (self.page == 1) {
        [self.tableView.mj_header endRefreshing];
    } else {
        [self.tableView.mj_footer endRefreshing];
    }
}

- (void)noMoreDataHandle {
    if (self.page == 1) {
        [self.tableView.mj_header endRefreshing];
    } else {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(downRefreshData)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(upLoadMoreData)];
    self.tableView.mj_footer.automaticallyHidden = YES;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(0);
    }];
    
    self.nullLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, (TDHeight - 128) / 2, TDWidth - 60, 39)];
    self.nullLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.nullLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.nullLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.nullLabel];
    self.nullLabel.hidden = YES;
    
    switch (self.whereFrom) {
        case TDAssistantFromOne:
            self.nullLabel.text = @"暂无待完成助教服务";
            break;
        case TDAssistantFromTwo:
            self.nullLabel.text = @"暂无已完成助教服务";
            break;
        case TDAssistantFromThree:
            self.nullLabel.text = @"暂无已取消助教服务";
            break;
        default:
            break;
    }

}

//时间格式
- (NSString *)dateFormatStart:(NSString *)startStr end:(NSString *)endStr {
    NSString *str = [startStr substringWithRange:NSMakeRange(11, 5)];
    NSString *str1 = [endStr substringWithRange:NSMakeRange(11, 5)];
    NSString *dateStr = [NSString stringWithFormat:@"%@~%@",str,str1];
    NSLog(@"%@ + %@ --->> %@ + %@ =====>> %@",startStr,endStr,str,str1,dateStr);
    return dateStr;
}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.whereFrom == TDAssistantFromThree ? 3 : 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDAssistantServiceModel *model = self.dataArray[indexPath.section];
    
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.row) {
        case 0: {
            TDAssistantTopCell *assistantTopCell = [[TDAssistantTopCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"assistantTopCell"];
            assistantTopCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            assistantTopCell.videoButton.tag = indexPath.section;
            [assistantTopCell.videoButton addTarget:self action:@selector(videoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            assistantTopCell.videoButton.hidden = YES;
            if (self.whereFrom == TDAssistantFromTwo) {
                if ([model.mp4_url.status intValue] == 2 && model.mp4_url.url.length > 0) {
                    assistantTopCell.videoButton.hidden = NO;
                }
            }
            assistantTopCell.titleLabel.text = [NSString stringWithFormat:@"%@",model.course_display_name];
            return assistantTopCell;
        }
            break;
        case 1: {
            TDAssistantCell *assistantCell = [[TDAssistantCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"assistantCell"];
            assistantCell.selectionStyle = UITableViewCellSelectionStyleNone;
            assistantCell.nameLabel.text = model.assistant_name;
            assistantCell.quetionLabel.text = model.question;
            assistantCell.whereFrom = self.whereFrom;
            [assistantCell.headerImage sd_setImageWithURL:[NSURL URLWithString:model.avatar_url.large] placeholderImage:[UIImage imageNamed:@"people"]];
            return assistantCell;
        }
            break;
        case 2: {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dateCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"dateCell"];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
            cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
            cell.textLabel.text = [NSString stringWithFormat:@"预约时间：%@",model.service_time];
            
            return cell;
        }
        default: {
            TDAssistantFootCell *assistantFootCell = [[TDAssistantFootCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"assistantFootCell"];
            assistantFootCell.selectionStyle = UITableViewCellSelectionStyleNone;
            assistantFootCell.whereFrom = self.whereFrom;
            assistantFootCell.startTime = model.service_begin_at;
            assistantFootCell.isComment = [model.is_comment intValue];
            assistantFootCell.score = [model.comment_infomation.score intValue];
            
            WS(weakSelf);
            assistantFootCell.endterButtonHandle = ^(){//进入教室
                [weakSelf getClassRoomPassword:model.id];
            };
            assistantFootCell.cancelButtonHandle = ^(){//取消
                [weakSelf cancelActionOrderId:model];
            };
            assistantFootCell.commentButtonHandle = ^(){//评论
                [weakSelf commentActinOfRow:indexPath withID:model.id];
            };
            
            return assistantFootCell;
        }
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        return 88;
    } else if (indexPath.row == 3) {
        return 48;
    }
    return 42;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 8;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TDAssistantServiceModel *model = self.dataArray[indexPath.section];
    TDTeachOrderDetailViewController *detailVC = [[TDTeachOrderDetailViewController alloc] init];
    detailVC.model = model;
    detailVC.statusStr = self.title;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark - 评论 
- (void)commentActinOfRow:(NSIndexPath *)indexPath withID:(NSString *)orderId {
    TDOrderCommentViewController *commentVC = [[TDOrderCommentViewController alloc] init];
    commentVC.tagsArray = self.tagsArray;
    commentVC.username = self.username;
    commentVC.assistantId = orderId;
    
    WS(weakSelf);
    commentVC.commentSuccessHandle = ^(){//评论成功，刷新页面
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    };
    [self.navigationController pushViewController:commentVC animated:YES];
}

#pragma mark - 视频回放
- (void)videoButtonAction:(UIButton *)sender {
    
    TDAssistantServiceModel *model = self.dataArray[sender.tag];
    
    TDVideoPlayerViewController *videoViewcontroller = [[TDVideoPlayerViewController alloc] init];
    videoViewcontroller.url = model.mp4_url.url;
    videoViewcontroller.courseName = model.course_display_name;
    [self.navigationController pushViewController:videoViewcontroller animated:YES];
}


#pragma mark - 取消
- (void)cancelActionOrderId:(TDAssistantServiceModel *)model {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:model.id forKey:@"id"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistantservers/cancelorder/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"取消订单 -- %@",responseObject);
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            if ([self.dataArray containsObject:model]) {
                [self.dataArray removeObject:model];
            }
            [self.tableView reloadData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Cancel_Order_Deal" object:nil];
            
        } else if ([code intValue] == 404) {
            [self.view makeToast:@"预订单不存在" duration:1.08 position:CSToastPositionCenter];
            
        } else {
            [self.view makeToast:@"取消订单失败" duration:1.08 position:CSToastPositionCenter];
        }
        NSLog(@"取消订单 %@ -- %@",responseDic[@"msg"],code);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:@"网络连接出错" duration:1.08 position:CSToastPositionCenter];
        NSLog(@"取消订单出错 -- %ld",(long)error.code);
    }];
}

#pragma mark - 进入教室
- (void)getClassRoomPassword:(NSString *)orderId {
    
    if (![self.toolModel networkingState]) {
        return;
    }
    
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"classroom://?"]]) {//先判断是否安装classroom
        [self gotoDownloadClassrooms];
        return;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:orderId forKey:@"id"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/getcourseroomkey/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"获取classroom密码 -- %@",responseObject);
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            
            NSString *password = responseDic[@"data"][@"student_join_password"];
            NSString *roomUrlStr = [NSString stringWithFormat:@"classroom://?password=%@&username=%@",password,self.username];
            NSURL *roomUrl = [NSURL URLWithString:roomUrlStr];
            
            if ([[UIApplication sharedApplication] canOpenURL:roomUrl]) {//调起全时
                [[UIApplication sharedApplication] openURL:roomUrl];
                
            } else {
                [self gotoDownloadClassrooms];
            }
            
        } else if ([code intValue] == 404) {
            [self.view makeToast:@"课程教室没有被创建" duration:1.08 position:CSToastPositionCenter];
        } else {
            [self.view makeToast:@"进入教室失败，请稍后重试" duration:1.08 position:CSToastPositionCenter];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:@"网络连接出错" duration:1.08 position:CSToastPositionCenter];
        NSLog(@"获取classroom密码 -- %ld",(long)error.code);
    }];

}

- (void)gotoDownloadClassrooms {
     NSLog(@" --- 还没下载 ----");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提醒"
                                                        message:@"您还没下载Classrooms，如需进入教室，请点击确定"
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end


