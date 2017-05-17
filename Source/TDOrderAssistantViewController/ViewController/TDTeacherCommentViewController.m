//
//  TDTeacherCommentViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/28.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeacherCommentViewController.h"
#import "TDBaseToolModel.h"
#import "TDTeacherTagModel.h"
#import "TDTeacherCommentModel.h"
#import "TDTeacherCommentCell.h"
#import "TDBaseView.h"

#import <MJRefresh/MJRefresh.h>
#import <MJExtension/MJExtension.h>
//#import "SDAutoLayout.h"

#define TopView_Width 228

@interface TDTeacherCommentViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) TDBaseToolModel *baseTool;

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *topArry;//头部标签
@property (nonatomic,strong) NSMutableArray *commentArray;//评论数组
@property (nonatomic,assign) NSInteger page;//页码
@property (nonatomic,assign) int maxPage;//最大页数
@property (nonatomic,strong) NSString *scoreStr;//评分
@property (nonatomic,strong) NSString *selectId;//选中的标签
@property (nonatomic,strong) UIButton *selectedButton;//选中的标签

@property (nonatomic,strong) UILabel *nullLabel;

@property (nonatomic,assign) BOOL canScroll;

@property (nonatomic,strong) TDBaseView *loadingView;

@end

@implementation TDTeacherCommentViewController

- (NSMutableArray *)topArry {
    if (!_topArry) {
        _topArry = [[NSMutableArray alloc] init];
    }
    return _topArry;
}

- (NSMutableArray *)commentArray {
    if (!_commentArray) {
        _commentArray = [[NSMutableArray alloc] init];
    }
    return _commentArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"COMMENTS", nil);
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    self.page = 1;
    self.selectedButton = [[UIButton alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptMessage:) name:@"superView_ScrollToTop" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptMessage:) name:@"childView_ScrollLeadTop" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
    [self.tableView addSubview:self.loadingView];
    
    [self requestTopData];
}


#pragma mark - notification
- (void)acceptMessage:(NSNotification *)notification {
    NSString *notificationName = notification.name;
    
    if ([notificationName isEqualToString:@"superView_ScrollToTop"]) {
        
        self.tableView.showsVerticalScrollIndicator = YES;
        self.canScroll = YES;
        
    } else if ([notificationName isEqualToString:@"childView_ScrollLeadTop"]) {
        
        [self.tableView setContentOffset:CGPointMake(0, 0)];
        self.tableView.showsVerticalScrollIndicator = NO;
        self.canScroll = NO;
    }
}

#pragma mark - 滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"下面的 ------ %f ; %f",self.tableView.contentOffset.y,scrollView.contentOffset.y);
    
    if (self.canScroll == NO) {
        [self.tableView setContentOffset:CGPointMake(0, 0)];
    }
    
    CGFloat offsetY = self.tableView.contentOffset.y;
    if (offsetY < 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"childView_ScrollLeadTop" object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 获取头部数据
- (void)requestTopData {
    
    if (![self.baseTool networkingState]) {
        return;
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/comment_summary/%@",ELITEU_URL,self.userName];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            self.scoreStr = responseDic[@"data"][@"comment_average_score"]; //评分
            
            NSArray *listArray = responseDic[@"data"][@"comment_tags"];//头部标签
            if (listArray.count > 0) {
                for (int i = 0; i < listArray.count; i ++) {
                    TDTeacherTagModel *topItem = [TDTeacherTagModel mj_objectWithKeyValues:listArray[i]];
                    if (topItem) {
                        [self.topArry addObject:topItem];
                    }
                }
            }
        } else {
            NSLog(@" 助教标签 --- %@",responseDic[@"msg"]);
        }
        
        [self setviewConstraint];
        [self requestCommentData:1];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"评论头部标签 error--%@",error);
    }];
}

#pragma mark - 上拉加载
- (void)topPullLoading {
    [self requestCommentData:2];
}

#pragma mark - 筛选
- (void)tagButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    self.page = 1;
    
    if (sender.selected) {
        sender.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
        self.selectedButton.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        self.selectedButton.selected = NO;
        self.selectedButton = sender;
        TDTeacherTagModel *topItem = self.topArry[sender.tag];
        topItem.isSelected = YES;
        self.selectId = topItem.id;
        
        [self requestCommentData:3];
        
    } else {
        self.selectedButton = nil;
        self.selectId = nil;
        [self requestCommentData:1];//都无选中，则显示总数据
        sender.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    }
}

#pragma mark- 获取评论数据
/*
 type:
 1 ： 下拉刷新或初次进来加载数据
 2 ： 上拉加载更多数据
 3 ： 点击标签筛选
 */
- (void)requestCommentData:(NSInteger)type {
    
    if (![self.baseTool networkingState]) {//网络监测
        self.loadingView.hidden = YES;
        [self.tableView reloadData];
        return;
    }
    
    if (self.page == 1) {
        [self.tableView.mj_footer resetNoMoreData];
        self.tableView.mj_footer.hidden = NO;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.userName forKey:@"username"];
    [params setValue:self.studentName forKey:@"student_username"];
    [params setValue:@"6" forKey:@"pagesize"];
    [params setValue:@(self.page) forKey:@"pageindex"];
    
    if (self.selectId.length > 0 ) {
        [params setValue:self.selectId forKey:@"tag_id"];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/comment/%@",ELITEU_URL,self.userName];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self.loadingView.hidden = YES;
        
        if (self.commentArray.count > 0 && self.page == 1) {
            [self.commentArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            NSArray *listArray = (NSArray *)responseDic[@"data"];
            
            if (listArray.count > 0) {
                for (int i = 0; i <listArray.count; i ++) {
                    TDTeacherCommentModel *detailItem = [TDTeacherCommentModel mj_objectWithKeyValues:listArray[i]];
                    if (detailItem) {
                        [self.commentArray addObject:detailItem];
                    }
                }
                self.page ++;
                
            } else {
                self.page > 1 ? self.page = 1 : self.page --;
            }
            
            if ([responseDic objectForKey:@"pages"]) {
                self.maxPage = [responseDic[@"pages"] intValue];
            }
           
        } else if ([code intValue] == 201) { //没有更多数据了
            if (type == 2) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
                self.tableView.mj_footer.hidden = YES;
            }
            [self.view makeToast:NSLocalizedString(@"NO_MORE_DATA", nil) duration:1.08 position:CSToastPositionCenter];
            
        } else if ([code intValue] == 404) { //该课程暂无此助教助教评论
            [self.view makeToast:NSLocalizedString(@"NO_COMMENTS_YET", nil) duration:1.08 position:CSToastPositionCenter];
        } else {
            [self.view makeToast:NSLocalizedString(@"NO_COMMENTS_YET", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
        NSLog(@"评论 --- %@ = %@",code,responseObject[@"msg"]);
        
        if (type == 2) {
            if (self.page >= self.maxPage) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
                self.tableView.mj_footer.hidden = YES;
            }else{
                [self.tableView.mj_footer endRefreshing];
            }
        } else {
            if (self.commentArray.count <= 6) {
                [self.tableView.mj_footer endRefreshingWithNoMoreData];
                self.tableView.mj_footer.hidden = YES;
            } else {
                [self.tableView.mj_footer resetNoMoreData];
                self.tableView.mj_footer.hidden = NO;
            }
        }
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self.loadingView.hidden = YES;
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"获取评论数据 error--%@",error);
    }];
}


#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.topArry.count == 0 && self.commentArray.count == 0 ? 1 : self.commentArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    if (self.topArry.count == 0 && self.commentArray.count == 0) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoCommentCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCommentCell"];
        }
        self.nullLabel = [[UILabel alloc] init];
        self.nullLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        self.nullLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
        self.nullLabel.text = NSLocalizedString(@"NO_COMMENTS_YET", nil);
        [cell addSubview:self.nullLabel];
        
        [self.nullLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(cell.mas_centerX);
            make.centerY.mas_equalTo(cell.mas_centerY).offset(-30);
        }];
        
        return cell;
        
    } else {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        TDTeacherCommentModel *detailItem = self.commentArray[indexPath.section];
        
        TDTeacherCommentCell *cell = [[TDTeacherCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDTeacherCommentCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.username = self.userName;
        
        cell.clickPraiseButton = ^(NSString *praiseNum,BOOL isPraise){
            detailItem.praise_num = praiseNum;
            detailItem.is_praise = isPraise;
        };
        cell.moreButtonActionHandle = ^(BOOL isOpen,float maxCommentLabelHeight){
            detailItem.click_Open = isOpen;
            detailItem.maxCommentLabelHeight = maxCommentLabelHeight;
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        };
        
        cell.detailItem = detailItem;
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.topArry.count == 0 && self.commentArray.count == 0) {
        return TDHeight - 108;
    } else {
        TDTeacherCommentModel *detailItem = self.commentArray[indexPath.section];
        return [self heightForCell:detailItem];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.topArry.count == 0 && self.commentArray.count == 0 ? 0 : 8;
}

- (int)heightForCell:(TDTeacherCommentModel *)detailItem {
    
    CGSize size = [detailItem.content boundingRectWithSize:CGSizeMake(TDWidth - 95, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14]} context:nil].size;
    
    if (size.height > 76.3) { //4行文本的高
        if (!detailItem.click_Open) {
            size.height = 76.3 + 27;
        } else if (detailItem.click_Open) {
            size.height = size.height + 27;
        }
    }
    
    int height = size.height + 26 + 100;
    if (detailItem.comment_tags.count > 0) {
        if (detailItem.content.length > 0) {
            height = size.height + ((detailItem.comment_tags.count - 1) / 3 + 1) * 26 + 16 + 100;
        } else {
            height = size.height + ((detailItem.comment_tags.count - 1) / 3 + 1) * 26 + 100;
        }
    }
    
    return height;
}


#pragma mark - UI
- (void)setviewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(self.view);
    }];
    
    if (self.topArry.count > 0) {
        self.tableView.tableHeaderView = [self headerView];
        self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(topPullLoading)];
        self.tableView.mj_footer.automaticallyHidden = YES;
    }
}

#pragma mark - 头部视图
- (UIView *)headerView {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, (self.topArry.count / 3 + 1) * 28 + 118)];
    headerView.backgroundColor = [UIColor whiteColor];
    
    UIView *topView = [[TDBaseView alloc] initWithTitle:NSLocalizedString(@"GENERAL_IMPRESSION", nil)];
    [headerView addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(headerView);
        make.top.mas_equalTo(headerView.mas_top).offset(11);
        make.height.mas_equalTo(39);
    }];
    
    /*
     星星
     */
    UIView *starView = [[UIView alloc] init];
    [headerView addSubview:starView];
    [starView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(headerView.mas_centerX);
        make.top.mas_equalTo(topView.mas_bottom).offset(3);
        make.size.mas_equalTo(CGSizeMake(TopView_Width, 39));
    }];
    
    int width = TopView_Width / 5;
    for (int i = 0; i < 5; i ++) {
        
        UIImageView *starImage = [[UIImageView alloc] init];
        starImage.contentMode = UIViewContentModeCenter;
        
        if (i > [self.scoreStr intValue]) {
            starImage.image = [UIImage imageNamed:@"star11"];
        } else {
            starImage.image = [UIImage imageNamed:@"star1"];
        }
        [starView addSubview:starImage];
        [starImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(starView.mas_left).offset(width * i);
            make.centerY.mas_equalTo(starView);
            make.width.mas_equalTo(width);
        }];
    }
    
    UIView *tagView = [[UIView alloc] init];
    [headerView addSubview:tagView];
    
    [tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(headerView.mas_left).offset(18);
        make.right.mas_equalTo(headerView.mas_right).offset(-18);
        make.top.mas_equalTo(starView.mas_bottom).offset(8);
        make.bottom.mas_equalTo(headerView.mas_bottom).offset(-8);
    }];
    
    /*
     标签 - 一行三个标签
     */
    int tagWidth = (TDWidth - 36) / 3;
    for (int i = 0; i < self.topArry.count; i ++) {
        int rang = i % 3;
        
        UIButton *tagButton = [[UIButton alloc] init];
        tagButton.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        [tagButton setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [tagButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        tagButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        tagButton.layer.cornerRadius = 11.0;
        tagButton.layer.borderWidth = 0.5;
        tagButton.layer.borderColor = [UIColor colorWithHexString:colorHexStr8].CGColor;
        tagButton.tag = i;
        [tagButton addTarget:self action:@selector(tagButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        TDTeacherTagModel *item = self.topArry[i];
        [tagButton setTitle:[NSString stringWithFormat:@"%@",item.name] forState:UIControlStateNormal];
        [tagView addSubview:tagButton];
        
        [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(tagView.mas_left).offset(rang * (tagWidth - 3) + 4);
            make.top.mas_equalTo(tagView.mas_top).offset(i / 3 * (23 + 5));
            make.size.mas_equalTo(CGSizeMake(tagWidth - 8, 23));
        }];
    }
    
    return headerView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
