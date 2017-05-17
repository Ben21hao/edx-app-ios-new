//
//  TDTeacherDetailViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeacherDetailViewController.h"
#import "TDTeacherMessageViewController.h"
#import "TDTeacherCommentViewController.h"
#import "TDBaseTableview.h"

#import <UIImageView+WebCache.h>
#import "edX-Swift.h"

#define TITLEVIEW_HEIGHT 45
#define HEADER_HEIGHT 239

@interface TDTeacherDetailViewController () <UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>

@property (nonatomic,strong) TDBaseTableview *tableView;

@property (nonatomic,strong) UIView *topView;
@property (nonatomic,strong) UIScrollView *titleView;
@property (nonatomic,strong) UIScrollView *contentView;
@property (nonatomic,strong) UIView *selectView;
@property (nonatomic,strong) UIView *sepView; //分割线

@property (nonatomic,strong) NSMutableArray *titleButtons;
@property (nonatomic,strong) NSMutableArray *lineViewArray;

@property (nonatomic,strong) TDTeacherMessageViewController *messageViewController;
@property (nonatomic,strong) TDTeacherCommentViewController *commentViewController;

@property (nonatomic,assign) BOOL canScroll;
@property (nonatomic,assign) BOOL isTopIsCanNotMoveTabView;
@property (nonatomic,assign) BOOL isTopIsCanNotMoveTabViewPre;

@end

@implementation TDTeacherDetailViewController

- (NSMutableArray *)titleButtons{
    if (_titleButtons == nil) {
        _titleButtons = [NSMutableArray array];
    }
    return _titleButtons;
}

- (NSMutableArray *)lineViewArray {
    if (_lineViewArray == nil) {
        _lineViewArray = [[NSMutableArray alloc] init];
    }
    return _lineViewArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"TA_DETAILS", nil);
    
    [self setViewConstraint];
    
    [self addAllChildrenView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptMessage:) name:@"childView_ScrollLeadTop" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellcell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellcell"];
    }
    self.contentView = [[UIScrollView alloc] init];
    self.contentView.pagingEnabled = YES;
    self.contentView.frame = CGRectMake(0, 0, TDWidth, TDHeight - TITLEVIEW_HEIGHT - 60);
    self.contentView.delegate = self;
    self.contentView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [cell addSubview:self.contentView];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return TDHeight - TITLEVIEW_HEIGHT - 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return TITLEVIEW_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, TITLEVIEW_HEIGHT)];
    
    self.titleView = [[UIScrollView alloc] init];
    self.titleView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.titleView.frame = CGRectMake(0, 0, TDWidth, TITLEVIEW_HEIGHT);
    [topView addSubview:self.titleView];
    
    [self setSepView];
    [self setUpSubtitle]; //设置标题页

    return topView;
}

#pragma mark - 设置按钮标题
- (void)setUpSubtitle {
    
    NSInteger count = self.childViewControllers.count;
    CGFloat x = 0;
    CGFloat h = 46;
    CGFloat btnW = TDWidth / count;
    
    for (int i = 0; i < count; i++) {
        x = i * btnW;
        
        UIViewController *vc = self.childViewControllers[i];
        
        UIButton *btn = [[UIButton alloc] init];
        btn.tag = i;
        btn.frame = CGRectMake(x, 0, btnW, h);
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        [btn setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [btn setTitle:vc.title forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.titleView addSubview:btn];
        
        [self.titleButtons addObject:btn];
        
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
        line.frame = CGRectMake(x + 10, h - 2, btnW - 20, 1);
        line.tag = i;
        [self.titleView addSubview:line];
        
        line.hidden = YES;
        [self.lineViewArray addObject:line];
        
        if (i == 0) {//默认选中第0个按钮
            [self btnClick:btn];
        }
    }
    self.contentView.contentSize = CGSizeMake(count * TDWidth, 0);
    self.contentView.pagingEnabled = YES;
}

#pragma mark - 选中
- (void)btnClick:(UIButton *)btn {
    
    [self setUpChildViewController:btn.tag];//把对应的子控制器添加上去
    [self selectButton:btn]; //让选中的标题颜色变蓝色
    
    CGFloat x = btn.tag * TDWidth; //滚动到对应位置
    self.contentView.contentOffset = CGPointMake(x, 0);
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if ([scrollView isEqual:self.contentView]) {//只有内容scrollview滚动时才有效
        
        NSInteger page = scrollView.contentOffset.x / TDWidth;
        UIButton *selButton = self.titleButtons[page];
        [self selectButton:selButton];
        [self setUpChildViewController:page];//添加子控制器的view
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
//    NSLog(@"上面的 ------ %f ===> %f",self.tableView.contentOffset.y,scrollView.contentOffset.y);
    
    CGFloat yOffset  = self.tableView.contentOffset.y;
    CGFloat tabOffsetY = [self.tableView rectForSection:0].origin.y;
    
    self.isTopIsCanNotMoveTabViewPre = self.isTopIsCanNotMoveTabView;
    
    if (yOffset >= tabOffsetY) {
        
        self.tableView.contentOffset = CGPointMake(0, tabOffsetY);//不能滑动
        self.isTopIsCanNotMoveTabView = YES;
        
    } else {
        self.isTopIsCanNotMoveTabView = NO;//可以滑动
        
    }
    if (self.isTopIsCanNotMoveTabView != self.isTopIsCanNotMoveTabViewPre) {
        
        if (self.isTopIsCanNotMoveTabView && !self.isTopIsCanNotMoveTabViewPre) {//子视图控制器滑动到顶端
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"superView_ScrollToTop" object:nil];
            self.canScroll = NO;
        }
        if(!self.isTopIsCanNotMoveTabView && self.isTopIsCanNotMoveTabViewPre){ //父视图控制器滑动到顶端
            
            if (!self.canScroll) {
                self.tableView.contentOffset = CGPointMake(0, tabOffsetY);
            }
        }
    }
}

#pragma mark - notification
- (void)acceptMessage:(NSNotification *)notification {
    self.canScroll = YES;
}

//添加对应的子控制器
- (void)setUpChildViewController:(NSInteger)index {
    
    UIViewController *vc = self.childViewControllers[index];
    if (vc.view.superview) {
        return;
    }
    CGFloat x = index * TDWidth;
    vc.view.frame = CGRectMake(x, 0, TDWidth, self.contentView.bounds.size.height);
    [self.contentView addSubview:vc.view];
}

#pragma mark - 选中按钮
- (void)selectButton:(UIButton *)sender {
    for (int i = 0 ; i < self.titleButtons.count; i ++) {
        UIButton *button = self.titleButtons[i];
        NSString *colorStr = i == sender.tag ? colorHexStr1 : colorHexStr9;
        [button setTitleColor:[UIColor colorWithHexString:colorStr] forState:UIControlStateNormal];
        
        UIView *line = self.lineViewArray[i];
        line.hidden = i == sender.tag ? NO : YES;
    }
}

#pragma mark - 加入子控制器
- (void)addAllChildrenView {
    
    for (int i = 0; i < 2 ; i ++ ) {
        if (i == 0) {
            self.messageViewController = [[TDTeacherMessageViewController alloc] init];
            self.messageViewController.model = self.model;
            self.messageViewController.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
            [self addChildViewController:self.messageViewController];
            
        } else {
            self.commentViewController = [[TDTeacherCommentViewController alloc] init];
            self.commentViewController.userName = self.model.username;
            self.commentViewController.studentName = self.myName;
            self.commentViewController.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
            [self addChildViewController:self.commentViewController];
        }
    }
}

//添加分割线
- (void)setSepView {
    
    CGFloat y = CGRectGetMaxY(self.titleView.frame);
    
    self.sepView = [[UIView alloc] init];
    self.sepView.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    self.sepView.frame = CGRectMake(0, y, TDWidth, 1);
    [self.titleView addSubview:self.sepView];
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.tableView = [[TDBaseTableview alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    self.tableView.tableHeaderView = [self setHeaderView];
}

#pragma mark - 头部视图
- (UIView *)setHeaderView {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    
    UIImageView *headerImage = [[UIImageView alloc] init];
    headerImage.layer.masksToBounds = YES;
    headerImage.layer.cornerRadius = 58.0;
    headerImage.layer.borderColor = [UIColor whiteColor].CGColor;
    headerImage.layer.borderWidth = 1;
    [headerView addSubview:headerImage];
    
    UILabel *nameLabel = [self setLabel];
    [headerView addSubview:nameLabel];
    
    UILabel *mottoLabel = [self setLabel];
    [headerView addSubview:mottoLabel];
    
    UIButton *authenButton = [self setButtonWithTitle:NSLocalizedString(@"VERIFIED_TA", nil) withColor:colorHexStr3];
    [headerView addSubview:authenButton];
    
    UIButton *orderButton = [self setButtonWithTitle:[Strings serviceOrderNumWithCount:[NSString stringWithFormat:@"%@",self.model.service_times]] withColor:colorHexStr3];
    [headerView addSubview:orderButton];
    
    if ([self.model.service_times intValue] == 0) {
        orderButton.hidden = YES;
    }
    
    [headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(headerView.mas_top).offset(28);
        make.centerX.mas_equalTo(headerView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(116, 116));
    }];
    
    [authenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(headerImage.mas_left).offset(0);
        make.top.mas_equalTo(headerImage.mas_top).offset(5);
        make.size.mas_equalTo(CGSizeMake(79, 20));
    }];
    
    [orderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(headerImage.mas_right).offset(0);
        make.bottom.mas_equalTo(headerImage.mas_bottom).offset(0);
        make.size.mas_equalTo(CGSizeMake(79, 20));
    }];
    
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(headerImage.mas_bottom).offset(8);
        make.left.mas_equalTo(headerView.mas_left).offset(13);
        make.right.mas_equalTo(headerView.mas_right).offset(-13);
    }];
    
    [mottoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(nameLabel.mas_bottom).offset(0);
        make.left.mas_equalTo(headerView.mas_left).offset(13);
        make.right.mas_equalTo(headerView.mas_right).offset(-13);
    }];
    
    headerImage.image = [UIImage imageNamed:@"tdIdentify"];
    //设置头像
    [headerImage sd_setImageWithURL:[NSURL URLWithString:self.model.avatar_url[@"large"]] placeholderImage:[UIImage imageNamed:@"default_big"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    nameLabel.text = self.model.name;
    mottoLabel.text = self.model.slogan;
    
    return headerView;
}

- (UIButton *)setButtonWithTitle:(NSString *)title withColor:(NSString *)colorStr {
    
    UIButton *customButton = [[UIButton alloc] init];
    customButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    customButton.backgroundColor = [UIColor colorWithHexString:colorStr];
    customButton.layer.cornerRadius = 10.0;
    [customButton setTitle:title forState:UIControlStateNormal];
    [customButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return customButton;
}

- (UILabel *)setLabel {
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:13];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines  = 0;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
