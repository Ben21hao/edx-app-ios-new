//
//  TDDownloadViewController.m
//  edX
//
//  Created by Ben on 2017/6/12.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDDownloadViewController.h"
#import "TDBaseScrollView.h"
#import "TDSubDownloadViewController.h"
#import "TDVidoDownloadViewController.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import "NSArray+OEXSafeAccess.h"

#define TitleView_Height 48

@interface TDDownloadViewController ()<UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) TDSubDownloadViewController *courseVC;
@property (nonatomic,strong) TDVidoDownloadViewController *videoSubVC;

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UIScrollView *titleView;
@property (nonatomic,strong) TDBaseScrollView *contentView;

@property (nonatomic,strong) TDBaseView *loadingView;

@property (nonatomic,strong) NSMutableArray *titleButtons;
@property (nonatomic,strong) NSMutableArray *lineArray;

@property (nonatomic, strong) OEXInterface *dataInterface;
@property (nonatomic, strong) NSMutableArray *arr_CourseData;

@property (strong, nonatomic) OEXCheckBox *btn_SelectAllEditing;
@property (strong, nonatomic) ProgressController *progressController;

@property (nonatomic,assign) BOOL isTableEditing;
@property (nonatomic,assign) BOOL isFullScreen;

@end

@implementation TDDownloadViewController

- (NSMutableArray *)titleButtons {
    if (!_titleButtons) {
        _titleButtons = [[NSMutableArray alloc] init];
    }
    return _titleButtons;
}

- (NSMutableArray *)lineArray {
    if (!_lineArray) {
        _lineArray = [[NSMutableArray alloc] init];
    }
    return _lineArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    [self setTitleLabel];
    [self setViewConstraint];
    [self addAllChildViewController];
    [self addTopTitlebutton];
    
    [self setNavigationStyle];
    
    self.dataInterface = [OEXInterface sharedInterface];
    [self.dataInterface setNumberOfRecentDownloads:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    [self addObservers];
    
    [self showLoadingView];
    [self getMyVideosTableData];
}

- (void)showLoadingView {
    
    self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
    [self.view addSubview:self.loadingView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TD_Download_Disapear" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXDownloadProgressChangedNotification object:nil];
}

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCompleteNotification:) name:OEXDownloadEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:OEXDownloadProgressChangedNotification object:nil];
}

#pragma update total download progress

- (void)downloadCompleteNotification:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;
    
    NSURLSessionTask* task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL* url = task.originalRequest.URL;
    
    if([OEXInterface isURLForVideo:url.absoluteString]) {
        [self getMyVideosTableData];
    }
}

- (void)updateTotalDownloadProgress:(NSNotification* )notification {
    [self updateNavigationItemButtons];
}

#pragma mark - 导航栏
- (void)setNavigationStyle {
    
    self.btn_SelectAllEditing = [[OEXCheckBox alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.btn_SelectAllEditing.tintColor = [[OEXStyles sharedStyles] navigationItemTintColor];
    self.btn_SelectAllEditing.hidden = YES;
    [self.btn_SelectAllEditing addTarget:self action:@selector(selectAllChanged:) forControlEvents:UIControlEventTouchUpInside];
    
    self.progressController = [[ProgressController alloc] initWithOwner:self router:self.environment.router dataInterface:self.environment.interface];
    self.navigationItem.rightBarButtonItem = [self.progressController navigationItem];
    [self.progressController hideProgessView];
}

- (void)updateNavigationItemButtons {
    
    NSMutableArray *barButtons = [[NSMutableArray alloc] init];
    if(self.isTableEditing) {
        [barButtons addObject:[[UIBarButtonItem alloc] initWithCustomView:self.btn_SelectAllEditing]];
    }
    if(![self.progressController progressView].hidden){
        [barButtons addObject:[self.progressController navigationItem]];
    }
//    if(barButtons.count != self.navigationItem.rightBarButtonItems.count) {
        self.navigationItem.rightBarButtonItems = barButtons;
//    }
}

- (void)selectAllChanged:(UIButton *)sender { //全选
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Navigation_SelectAll_Handle" object:nil];
}

#pragma mark - 数据
- (void)getMyVideosTableData {
    
    self.arr_CourseData = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [self.dataInterface coursesAndVideosForDownloadState:OEXDownloadStateComplete] ];
    
    // Populate both ALL & RECENT Videos Table data
    for(NSDictionary *dict in arrCourseAndVideo) {
        NSMutableDictionary* mutableDict = [dict mutableCopy];
        
        NSString *strSize = [[NSString alloc] initWithString: [self calculateVideosSizeInCourse:[mutableDict objectForKey:CAV_KEY_VIDEOS]] ];
        NSMutableArray* sortedArray = [mutableDict objectForKey:CAV_KEY_VIDEOS];
        NSSortDescriptor* sortDesc = [[NSSortDescriptor alloc] initWithKey:@"completedDate" ascending:NO selector:@selector(compare:)];
        [sortedArray sortUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        NSMutableArray* arr_SortedArray = [sortedArray mutableCopy];
        NSDictionary* videos = @{CAV_KEY_COURSE: [mutableDict objectForKey:CAV_KEY_COURSE],
                                 CAV_KEY_VIDEOS: [mutableDict objectForKey:CAV_KEY_VIDEOS],
                                 CAV_KEY_RECENT_VIDEOS: arr_SortedArray,
                                 CAV_KEY_VIDEOS_SIZE: strSize};
        
        [self.arr_CourseData addObject:videos];
    }
    
    [self reloadDownloadData];
}

- (NSString*)calculateVideosSizeInCourse:(NSArray*)arrvideo {
    
    NSString *strSize = nil;
    double size = 0.0;
    
    for(OEXHelperVideoDownload* video in arrvideo) {
        double videoSize = [video.summary.size doubleValue];
        double sizeInMegabytes = (videoSize / 1024) / 1024;
        size += sizeInMegabytes;
    }
    strSize = [NSString stringWithFormat:@"%.2fMB", size];
    return strSize;
}

- (void)reloadDownloadData { //刷新数据
    
    [self.loadingView removeFromSuperview];
    
    self.courseVC.arr_CourseData = self.arr_CourseData;
    [self.courseVC.tableView reloadData];
    
    self.videoSubVC.arr_CourseData = self.arr_CourseData;
    [self.videoSubVC.tableView reloadData];
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.titleView = [[UIScrollView  alloc] initWithFrame:CGRectMake(0, 0, TDWidth, TitleView_Height)];
    self.titleView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.titleView];
    
    self.contentView = [[TDBaseScrollView alloc] initWithFrame:CGRectMake(0, TitleView_Height, TDWidth, TDHeight - TitleView_Height - 60)];
    self.contentView.pagingEnabled = YES;
    self.contentView.delegate = self;
    self.contentView.bounces = NO;
    self.contentView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.contentView];
    
    UILabel *sss = [[UILabel alloc] initWithFrame:CGRectMake(0, TitleView_Height - 1, TDWidth, 1)];
    sss.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [self.titleView addSubview:sss];
}

- (void)addAllChildViewController {
    
    self.courseVC = [[TDSubDownloadViewController alloc] init];
    self.courseVC.environment = self.environment;
    [self addChildViewController:self.courseVC];
    
    self.videoSubVC = [[TDVidoDownloadViewController alloc] init];
    self.videoSubVC.dataInterface = self.dataInterface;
    
    WS(weakSelf);
    self.videoSubVC.judgEditeHandle = ^(BOOL isTableEditing){
        weakSelf.isTableEditing = isTableEditing;
        [weakSelf updateNavigationItemButtons];
    };
    self.videoSubVC.hideEditeHandle = ^(BOOL isHidden){
        weakSelf.btn_SelectAllEditing.hidden = isHidden;
    };
    self.videoSubVC.checkEditeHandle = ^(BOOL isChecked){
        weakSelf.btn_SelectAllEditing.checked = isChecked;
    };
    self.videoSubVC.reloadSubDataHandle = ^{
        [weakSelf.courseVC.tableView reloadData];
    };
    self.videoSubVC.fullScreenHanle = ^(BOOL isFullScreen){
        weakSelf.isFullScreen = isFullScreen;
    };
    [self addChildViewController:self.videoSubVC];
}

- (void)addTopTitlebutton {

    NSInteger count = self.childViewControllers.count;
    CGFloat height = TitleView_Height - 2;
    CGFloat width = TDWidth / count;
    
    for (int i = 0; i < count; i ++) {
        UIButton *titleButton = [[UIButton alloc] initWithFrame:CGRectMake(i * width, 0, width, height)];
        titleButton.tag = i;
        titleButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        [titleButton setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [titleButton addTarget:self action:@selector(titleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.titleView addSubview:titleButton];
        
        [self.titleButtons addObject:titleButton];
        
        UIView *sliView = [[UIView alloc] initWithFrame:CGRectMake(width * i, TitleView_Height - 2, width, 2)];
        sliView.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
        sliView.hidden = YES;
        [self.titleView addSubview:sliView];
        
        [self.lineArray addObject:sliView];
        
        if (i == 0) {
            [titleButton setTitle:NSLocalizedString(@"ALL_VIDEOS", nil) forState:UIControlStateNormal];
            [self titleButtonAction:titleButton];
        } else {
            [titleButton setTitle:NSLocalizedString(@"RECENT_VIDEOS", nil) forState:UIControlStateNormal];
        }
    }
    self.contentView.contentSize = CGSizeMake(count * TDWidth, 0);
}

- (void)titleButtonAction:(UIButton *)sender {
    
    [self selectButton:sender]; //让选中的标题颜色变蓝色
    [self setUpChildViewController:sender.tag];//把对应的子控制器添加上去
    
    CGFloat x = sender.tag * TDWidth; //滚动到对应位置
    self.contentView.contentOffset = CGPointMake(x, 0);
}

- (void)selectButton:(UIButton *)sender {
    
    if (sender.tag == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TD_SubDowload_Appear" object:nil];
        self.btn_SelectAllEditing.hidden = YES;
        self.btn_SelectAllEditing.checked = NO;
    }
    
    for (int i = 0 ; i < self.titleButtons.count; i ++) {
        UIButton *button = self.titleButtons[i];
        NSString *colorStr = i == sender.tag ? colorHexStr1 : colorHexStr9;
        [button setTitleColor:[UIColor colorWithHexString:colorStr] forState:UIControlStateNormal];

        UIView *sliView = self.lineArray[i];
        sliView.hidden = i == sender.tag ? NO : YES;
    }
}

#pragma mark - UIViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    NSInteger page = scrollView.contentOffset.x / TDWidth;
    UIButton *selButton = self.titleButtons[page];
    [self selectButton:selButton];
    [self setUpChildViewController:page];//添加子控制器的view
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (otherGestureRecognizer.state == UIGestureRecognizerStateBegan && self.contentView.contentOffset.x == 0) {
        return YES;
    }
    return NO;
}

/* 添加对应的子控制器 */
- (void)setUpChildViewController:(NSInteger)index {
    
    UIViewController *vc = self.childViewControllers[index];
    if (vc.view.superview) {
        return;
    }
    CGFloat x = index * TDWidth;
    vc.view.frame = CGRectMake(x, 0, TDWidth, self.contentView.bounds.size.height);
    [self.contentView addSubview:vc.view];
}

#pragma mark - 导航栏标题
- (void)setTitleLabel {
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, TDWidth - 188, 44)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.text = [Strings myVideos];
    self.navigationItem.titleView = self.titleLabel;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.isFullScreen;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
