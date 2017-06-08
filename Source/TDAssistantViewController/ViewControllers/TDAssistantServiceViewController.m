//
//  TDAssistantServiceViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDAssistantServiceViewController.h"
#import "TDSubServiceViewController.h"
#import "TDBaseScrollView.h"

#import "edX-Swift.h"
#import "OEXRouter.h"

#define TITLEVIEW_HEIGHT 45

@interface TDAssistantServiceViewController () <UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UIScrollView *titleView;
@property (nonatomic,strong) TDBaseScrollView *contentView;
@property (nonatomic,strong) UIView *selectView;
@property (nonatomic,strong) UIView *sepView; //分割线

@property (nonatomic,strong) NSMutableArray *titleButtons;

@end

@implementation TDAssistantServiceViewController

- (NSMutableArray *)titleButtons{
    if (_titleButtons == nil) {
        _titleButtons = [NSMutableArray array];
    }
    return _titleButtons;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setViewConstraint];
    [self addAllChildrenView];
    [self setUpSubtitle]; //设置标题
    [self setSepView]; //添加分割线
    [self setSliView]; //设置指示view
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"TA_SERVICE", nil);
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.titleView = [[UIScrollView alloc] init];
    self.titleView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.titleView.frame = CGRectMake(0, 0, TDWidth, 45);
    [self.view addSubview:self.titleView];

    self.contentView = [[TDBaseScrollView alloc] init];
    self.contentView.pagingEnabled = YES;
    self.contentView.bounces = NO;
    self.contentView.frame = CGRectMake(0, TITLEVIEW_HEIGHT, TDWidth, TDHeight - TITLEVIEW_HEIGHT - 60);
    self.contentView.delegate = self;
    self.contentView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.contentView];
}

#pragma mark - 加入子控制器
- (void)addAllChildrenView {
    
    for (int i = 0; i < 3 ; i ++ ) {
        TDSubServiceViewController *subViewController = [[TDSubServiceViewController alloc] init];
        subViewController.whereFrom = i;
        subViewController.username = self.username;
        subViewController.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        [self addChildViewController:subViewController];
    }
}

#pragma mark - 设置按钮标题
- (void)setUpSubtitle {
    
    NSInteger count = self.childViewControllers.count;
    CGFloat x = 0;
    CGFloat h = 46;
    CGFloat btnW = TDWidth / count;
    
    for (int i = 0; i < count; i++) {
        UIViewController *vc = self.childViewControllers[i];
        
        UIButton *btn = [[UIButton alloc] init];
        btn.tag = i;
        x = i * btnW;
        btn.frame = CGRectMake(x, 0, btnW, h);
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        [btn setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [btn setTitle:vc.title forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.titleView addSubview:btn];
        
        [self.titleButtons addObject:btn];
        
        if (i == 0) {//默认选中第0个按钮
            [self btnClick:btn];
        }
    }
    self.contentView.contentSize = CGSizeMake(count * TDWidth, 0);
    self.contentView.pagingEnabled = YES;
}

//添加分割线
- (void)setSepView {
    
    CGFloat y = CGRectGetMaxY(self.titleView.frame);
    self.sepView = [[UIView alloc] init];
    self.sepView.backgroundColor = [UIColor colorWithHexString:@"#E6E9ED"];
    self.sepView.frame = CGRectMake(0, y, TDWidth, 1);
    [self.view addSubview:self.sepView];
}

//设置指示view
- (void)setSliView {
    
    CGFloat x = TDWidth / self.titleButtons.count;
    for (int i = 0; i < self.titleButtons.count; i++) {
        
        UIView *sliV = [[UIView alloc] init];
        sliV.hidden = YES;
        sliV.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
        sliV.tag = i;
        sliV.frame = CGRectMake(x * i, -1, x, 2);
        
        [self.sepView addSubview:sliV];
        
        if (i == 0) {
            [self selView:i];
        }
    }
}

#pragma mark - 选中按钮
- (void)selectButton:(UIButton *)sender {
    
    for (int i = 0 ; i < self.titleButtons.count; i ++) {
        UIButton *button = self.titleButtons[i];
        NSString *colorStr = i == sender.tag ? colorHexStr1 : colorHexStr9;
        [button setTitleColor:[UIColor colorWithHexString:colorStr] forState:UIControlStateNormal];
    }
    [self setSliView];
}

- (void)selView:(NSInteger)i {
    
    UIView *vc = self.sepView.subviews[i];
    self.selectView.hidden = YES;
    vc.hidden = NO;
    self.selectView = vc;
}

#pragma mark - 选中
- (void)btnClick:(UIButton *)btn {
    
    [self selectButton:btn]; //让选中的标题颜色变蓝色
    [self setUpChildViewController:btn.tag];//把对应的子控制器添加上去
    
    CGFloat x = btn.tag * TDWidth; //滚动到对应位置
    self.contentView.contentOffset = CGPointMake(x, 0);
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
    
    [self selView:index];
    
    UIViewController *vc = self.childViewControllers[index];
    if (vc.view.superview) {
        return;
    }
    CGFloat x = index * TDWidth;
    vc.view.frame = CGRectMake(x, 0, TDWidth, self.contentView.bounds.size.height);
    [self.contentView addSubview:vc.view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end



