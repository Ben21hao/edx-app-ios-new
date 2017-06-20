//
//  TDCouponViewController.m
//  edX
//
//  Created by Ben on 2017/6/6.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDCouponViewController.h"
#import "TDSubCouponViewController.h"
#import "TDBaseScrollView.h"
#import "WYAlertView.h"

#import "edX-Swift.h"
#import "OEXRouter.h"

#define TITLEVIEW_HEIGHT 45

@interface TDCouponViewController () <UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UIScrollView *titleView;
@property (nonatomic,strong) TDBaseScrollView *contentView;
@property (nonatomic,strong) UIView *selectView;
@property (nonatomic,strong) UIView *sepView; //分割线
@property (nonatomic,strong) WYAlertView *exchangeAlertView;

@property (nonatomic,strong) NSMutableArray *titleButtons;
@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDCouponViewController

- (NSMutableArray *)titleButtons{
    if (_titleButtons == nil) {
        _titleButtons = [NSMutableArray array];
    }
    return _titleButtons;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"COUPON_PAPER", nil);
    [self.rightButton setTitle:NSLocalizedString(@"EXCHANGE_TITLE", nil) forState:UIControlStateNormal];
    
    
    
    self.toolModel = [[TDBaseToolModel alloc] init];
    
    WS(weakSelf);
    self.rightButtonHandle = ^(){ //兑换
        [weakSelf exchangeAction];
    };
    
    [self setViewConstraint];
    [self addAllChildrenView];
    [self setUpSubtitle]; //设置标题
    [self setSepView]; //添加分割线
    [self setSliView]; //设置指示view
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

#pragma mark - 兑换优惠券
- (void)exchangeAction {
    
    self.exchangeAlertView = [[WYAlertView alloc] initWithTitle:NSLocalizedString(@"EXCHANGE_COUPON", nil) message:nil cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) rightButtonTitle:NSLocalizedString(@"OK", nil) beTextField:YES];
    self.exchangeAlertView.text.placeholder = NSLocalizedString(@"ENTER_COUPON_NUM", nil);
    
    [self.exchangeAlertView show];
    [self.exchangeAlertView.rightbtn addTarget:self action:@selector(exchangeCoupons) forControlEvents:UIControlEventTouchUpInside];
}

//兑换优惠券
- (void)exchangeCoupons {
    
    if (![self.toolModel networkingState]) {
        [self disconnect];
    }
    
    if (self.exchangeAlertView.text.text.length == 0) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"code"] = self.exchangeAlertView.text.text;
    
    NSString *url = [NSString stringWithFormat: @"%@/api/mobile/v0.5/market/save_coupon/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
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
    
//    [self.firstVC  getNewData];
//    [self.secondVC getNewData];
//    [self.thirdVC getNewData];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TD_User_Coupon_Exchange_Sucess" object:nil];
    
    [self srollToFirstView];
}

- (void)srollToFirstView {
    UIButton *selButton = self.titleButtons[0];
    [self btnClick:selButton];
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
        TDSubCouponViewController *subViewController = [[TDSubCouponViewController alloc] init];
        subViewController.whereFrom = i + 1;
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
