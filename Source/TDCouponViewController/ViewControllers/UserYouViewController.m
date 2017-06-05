//
//  UserYouViewController.m
//  edX
//
//  Created by Elite Edu on 16/8/26.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "UserYouViewController.h"
#import "UIColor+JHHexColor.h"
#import "UserFirstViewController.h"
#import "UserSecondViewController.h"
#import "UserThirdViewController.h"
#import "UIColor+OEXHex.h"
#import <AFNetworking.h>
#import "UserCouponItem.h"
#import <MJExtension.h>
#import "WYAlertView.h"
#import "JHFindPWDView.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"
#import "OEXFlowErrorViewController.h"
#import "TDBaseScrollView.h"

@interface UserYouViewController () <UIScrollViewDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) UIScrollView *titleView;
@property (nonatomic,strong) TDBaseScrollView *contentView;
@property (nonatomic,strong) NSMutableArray *titleButtons;
@property (nonatomic,weak) UIView *sepView; //分割线
@property (nonatomic,weak) UIView *selectedView;

@property (nonatomic,strong) UserFirstViewController *firstVC;//TODO:样式一样，不需要用三个控制器，只需要用一个控制器就可以
@property (nonatomic,strong) UserSecondViewController *secondVC;
@property (nonatomic,strong) UserThirdViewController *thirdVC;
@property (nonatomic,strong) WYAlertView *exchangeV;
@property (nonatomic,strong) AFHTTPSessionManager *manager;
@property (nonatomic, assign) BOOL reachable;//网络情况Bool值

@end

@implementation UserYouViewController
- (NSMutableArray *)titleButtons{
    if (_titleButtons == nil) {
        _titleButtons = [NSMutableArray array];
    }
    return _titleButtons;
}

- (AFHTTPSessionManager *)manager{
    if (_manager == nil) {
        _manager = [AFHTTPSessionManager manager];
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpTitleView];//添加顶部标题
    [self setUpContentView];//设置内容视图
    [self setUpAllChildeView];//添加子控制器
    [self setUpSubtitle];//设置标题
    [self setSepView];//添加分割线
    [self setSliView];//设置指示view
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setLoadDataView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"COUPON_PAPER", nil);
    [self.rightButton setTitle:NSLocalizedString(@"EXCHANGE_TITLE", nil) forState:UIControlStateNormal];
    
    WS(weakSelf);
    self.rightButtonHandle = ^(){
        [weakSelf exchange];
    };
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.loadIngView removeFromSuperview];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (otherGestureRecognizer.state == UIGestureRecognizerStateBegan && self.contentView.contentOffset.x == 0) {
        return YES;
    }
    return NO;
}

//添加顶部标题视图
- (void)setUpTitleView{
    
    self.titleView = [[UIScrollView alloc] init];
    self.titleView.frame = CGRectMake(0, 0, TDWidth, 45);
    self.titleView.backgroundColor = [[UIColor alloc] initWithRGBHex:0xFCFCFC alpha:1];
    [self.view addSubview:self.titleView];
}

//设置内容视图
- (void)setUpContentView {
    
    self.contentView = [[TDBaseScrollView alloc] init];
    CGFloat y = CGRectGetMaxY(self.titleView.frame);
    self.contentView.frame = CGRectMake(0, y, TDWidth, TDHeight - y);
    self.contentView.delegate = self;
    [self.view addSubview:self.contentView];
}

#pragma mark - 添加子控制器
- (void)setUpAllChildeView{
    
    self.firstVC = [[UserFirstViewController alloc] init];
    self.firstVC.username = self.username;
    self.firstVC.view.backgroundColor = [UIColor blueColor];
    [self addChildViewController:self.firstVC];
    
    self.secondVC = [[UserSecondViewController alloc] init];
    self.secondVC.username = self.username;
    self.secondVC.view.backgroundColor = [UIColor yellowColor];
    [self addChildViewController:self.secondVC];
    
    self.thirdVC = [[UserThirdViewController alloc] init];
    self.thirdVC.username = self.username;
    self.thirdVC.view.backgroundColor = [UIColor greenColor];
    [self addChildViewController:self.thirdVC];
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
    UIView *sepView = [[UIView alloc] init];
    sepView.backgroundColor = [UIColor colorWithHexString:@"#E6E9ED"];
    sepView.frame = CGRectMake(0, y, TDWidth, 1);
    [self.view addSubview:sepView];
    self.sepView = sepView;
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
    
    [sender setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
    [self setSliView];
}

- (void)selView:(NSInteger)i {
    
    UIView *vc = self.sepView.subviews[i];
    self.selectedView.hidden = YES;
    vc.hidden = NO;
    self.selectedView = vc;
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

//添加对应的子控制器
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


#pragma mark -- 兑换优惠券
//兑换
- (void)exchange {
    _exchangeV = [[WYAlertView alloc] initWithTitle:NSLocalizedString(@"EXCHANGE_COUPON", nil) message:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) rightButtonTitle:NSLocalizedString(@"OK", nil) beTextField:YES];
    _exchangeV.text.placeholder = NSLocalizedString(@"ENTER_COUPON_NUM", nil);
    [_exchangeV show];
    [_exchangeV.rightbtn addTarget:self action:@selector(exchangeCoupons) forControlEvents:UIControlEventTouchUpInside];
}
//0.断网
- (void)disconnect {
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//1.兑换成功
- (void)exchangeSuccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EXCHANGE_SUCCESS", nil)
                                                    message:NSLocalizedString(@"EXCHANGE_AND_USE", nil)
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    alert.delegate = self;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    [self.firstVC  getNewData];
    [self.secondVC getNewData];
    [self.thirdVC getNewData];
}

//2.您已经领用了优惠券
- (void)alreadyUsed{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"HAD_EXCHANGE", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//3.很抱歉，优惠券已经领用完了
- (void)couponsUp{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"HAS_NO_COUPON", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//4.优惠券兑换时间未到！
- (void)notExchangeTime{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"COUPON_TIME_EARLY", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//5.优惠券已过期！
- (void)couponsOutTime{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"COUPON_TIME_LATER", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//6.优惠券已失效！
- (void)couponsInvalid{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message: NSLocalizedString(@"COUPON_NO_USERENABLE", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//7.优惠券不存在!
- (void)notExist{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"NO_INVALIDE_COUPON", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}

//8.企业优惠券兑换失败
- (void)failExchangeCompanyCode{
    [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:NSLocalizedString(@"EXCHANGE_FAIL", nil)
                                                            message:NSLocalizedString(@"COMPANY_COUPON_FAIL", nil)
                                                   onViewController:self.navigationController.view
                                                         shouldHide:YES];
}
//兑换优惠券
- (void)exchangeCoupons{
    //0.网络情况
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];
    if (!self.reachable) {
        [self disconnect];
    }
    _manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"code"] = _exchangeV.text.text;
    
    NSString *url = [NSString stringWithFormat: @"%@/api/mobile/v0.5/market/save_coupon/",ELITEU_URL];
    [_manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *code = responseObject[@"code"];
        NSString *msg = responseObject[@"msg"];
        int codeValue = [code intValue];
        
        if (codeValue == 200) { //1.兑换成功
            [self exchangeSuccess];
            
        } else if (codeValue == 312) { //2.您已经领用了优惠券！
            [self alreadyUsed];
            
        } else if (codeValue == 313) {//3.很抱歉，优惠券已经领用完了！
            [self couponsUp];
            
        } else if (codeValue == 504) { //企业优惠券兑换失败！
            [self  failExchangeCompanyCode];
            
        } else if ([msg isEqualToString:@"优惠券兑换时间未到！"]) { //4.优惠券兑换时间未到!
            [self notExchangeTime];
            
        } else if (codeValue == 502) {//5.优惠券已过期!
            [self couponsOutTime];
            
        } else if ([msg isEqualToString:@"优惠券已失效！"]) { //6. 优惠券已失效!
            [self couponsInvalid];
            
        } else if (codeValue == 404) { //7.优惠券不存在!
            [self notExist];
            
        } else {
            [self.view makeToast:NSLocalizedString(@"EXCHANGE_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--exchange--%@",error);
    }];
}
/*
200 兑换成功!
312 您已经领用了优惠券！
313 很抱歉，优惠券已经领用完了！
400 请求参数缺失!
404 优惠券不存在!
405 GET请求不被允许，请使用POST请求！
406 用户不存在！
502 优惠券已过期!
504 企业优惠券兑换失败！
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
