//
//  SubmitCourseViewController.m
//  edX
//
//  Created by Elite Edu on 16/10/9.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "SubmitCourseViewController.h"
#import "TDBuySuccessViewController.h"
#import "WaitForPayViewController.h"
#import "OEXFlowErrorViewController.h"
#import "CouponsViewController.h"

#import "WaitForPayTableViewCell.h"
#import "PayTableViewCell.h"
#import "SubmiteSecondCell.h"

#import "JHCouponsAlertView.h"

#import "TDBaseToolModel.h"
#import "CouponsNameItem.h"
#import "ChooseCourseItem.h"
#import "OEXAppDelegate.h"
#import "edX-Swift.h"
#import "OEXRouter.h"

#import <MJExtension/MJExtension.h>
#import <UIImageView+WebCache.h>
#import "UIColor+JHHexColor.h"
#import <AFNetworking.h>
#import "Reachability.h"
#import "OEXSession.h"

#import <AlipaySDK/AlipaySDK.h>
#import "aliPayParamsItem.h"
#import "DataSigner.h"
#import "dataUrlItem.h"
#import "aliData.h"
#import "Order.h"

#import "weChatParamsItem.h"
#import "WeChatPay.h"
#import "WXApi.h"

#import "Encryption.h"//md5加密

@interface SubmitCourseViewController ()<JHCouponsAlertViewDelegate,UIAlertViewDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic,strong) NSArray *leftTielArray;
@property (nonatomic,strong) NSArray *payImgArr;
@property (nonatomic,strong) NSArray *payImgArr1;
@property (nonatomic,strong) UIView *bottomView;
@property (nonatomic,strong) UILabel *moneyLabel;
@property (nonatomic,strong) UIButton *submitCourse;

@property (nonatomic,assign) NSInteger payWay;

@property (nonatomic,strong) weChatParamsItem *weChatItem;
@property (nonatomic,strong) aliPayParamsItem *aliPayItem;

@property (nonatomic,assign) float payMoney;
@property (nonatomic,assign) float cutBaodian;
@property (nonatomic,strong) JHCouponsAlertView *inputAlert;
@property (nonatomic,strong) NSNumber *remain_score;
@property (nonatomic,strong) NSString *score_rate;
@property (nonatomic,strong) NSString *usedcoin;
@property (nonatomic,strong) NSMutableArray *courseID;
@property (nonatomic,strong) NSString *courseIds;//拼接所有课程
@property (nonatomic,assign) float maxCoin;//最多可用宝典
@property (nonatomic,strong) NSString *warmingStr;
@property (nonatomic,strong) NSIndexPath *first;

@property (nonatomic,strong) NSString *couponStr;
@property (nonatomic,strong) NSString *baodianStr;
@property (nonatomic,assign) BOOL isWechatInstall;
@property (nonatomic,strong) NSString *orderId;

@property (nonatomic,strong) NSString *coupon_id;//优惠券id
@property (nonatomic,assign) BOOL isCampony;
@property (nonatomic,assign) BOOL hadCreateOrder;//是否已创建订单

@property (nonatomic,strong) UIButton *backButton;
@property (nonatomic,assign) BOOL isNoCoupon;
@property (nonatomic,strong) TDBaseToolModel *baseTool;

@end

@implementation SubmitCourseViewController
static NSString *identify = @"ChooseCourseCell";
static NSString *payIdentify = @"PayTableViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.payWay = 1;//默认微信
    self.couponStr = NSLocalizedString(@"SELECT_COUPON", nil);
    self.payMoney = self.totalM;
    self.cutBaodian = self.totalM;
    self.isCampony = NO;
    self.hadCreateOrder = NO;
    self.isNoCoupon = NO;
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    
    [self setText];
    
    [self setCell];//注册cell
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    _courseID = [NSMutableArray array];
    [self setParams];
    
    [self setBottomV];
    [self getLastCoupons];//获得剩余宝典
    
    [self setLoadDataView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"aliPaySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backButtonNotiAction) name:@"aliPayFail" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"BALANCE_BUY", nil);
    self.leftButton.hidden = YES;
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [self.backButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    self.backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    [self.backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initialization];//选中第一个支付方式
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - 返回
- (void)backButtonAction:(UIButton *)sender {
    if (self.hadCreateOrder) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)backButtonNotiAction {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)initialization { //选中第一个
    if (self.isWechatInstall) {
        self.payWay = 1;
    } else {
        self.payWay = 2;
    }
    _first = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView selectRowAtIndexPath:_first animated:YES scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - 支付成功
- (void)paySuccess {
    TDBuySuccessViewController *buySuccessVC = [[TDBuySuccessViewController alloc] init];
    buySuccessVC.orderId = self.orderId;
    NSLog(@"success %@",buySuccessVC.orderId);
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:buySuccessVC animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPaySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPayFail" object:nil];
}

- (void)setParams{
    
    if (_coupon_id == nil) {
        _coupon_id = @"0";
    }
    if (_activity_id == nil) {
        _activity_id = @"0";
    }
    if (self.usedcoin == nil) {
        self.usedcoin = @"0";
    }
    for (ChooseCourseItem *courseItem in _array0) {
        [_courseID addObject:courseItem.course_id];
    }
    self.courseIds = [_courseID componentsJoinedByString:@","];
}

- (void)setCell{
    [self.tableView registerNib:[UINib nibWithNibName:@"WaitForPayTableViewCell" bundle:nil] forCellReuseIdentifier:identify];
    [self.tableView registerNib:[UINib nibWithNibName:@"PayTableViewCell" bundle:nil] forCellReuseIdentifier:payIdentify];
}

- (void)setText{
    
    self.isWechatInstall = [WXApi isWXAppInstalled];
    self.leftTielArray = self.hideShowPurchase ? @[NSLocalizedString(@"COUPON_PAPER", nil),NSLocalizedString(@"COINS_VALUE", nil)] : @[];
    _payImgArr = self.isWechatInstall ? @[@"weChat",@"zhifu"] : @[@"zhifu"];
    _payImgArr1 = self.isWechatInstall ? @[NSLocalizedString(@"WECHAT_PAY", nil),NSLocalizedString(@"ALI_PAY", nil)] : @[NSLocalizedString(@"ALI_PAY", nil)];
}

- (void)setBottomV {
    
    CGFloat height = 44;
    
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.bottomView];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.height.mas_equalTo(height);
    }];
    
    self.submitCourse = [[UIButton alloc] init];
    self.submitCourse.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.submitCourse.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.submitCourse.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.submitCourse.titleLabel.numberOfLines = 0;
    [self.submitCourse addTarget:self action:@selector(submitCoursesPayAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.submitCourse setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.submitCourse setTitle:NSLocalizedString(@"HAND_MONEY", nil) forState:UIControlStateNormal];
    [self.bottomView addSubview:self.submitCourse];
    
    if ([self.giftCoin floatValue] > 0) {
        NSString *coinNumStr = [Strings giveCoinsNumberWithCount:self.giftCoin];
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"HAND_MONEY", nil)] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],NSForegroundColorAttributeName : [UIColor whiteColor]}];
        NSMutableAttributedString *str2 = [self.baseTool setDetailString:coinNumStr withFont:11 withColorStr:colorHexStr3];
        [str1 appendAttributedString:str2];
        [self.submitCourse setAttributedTitle:str1 forState:UIControlStateNormal];
    }
    
    [self.submitCourse mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.mas_equalTo(self.bottomView);
        make.width.mas_equalTo(99);
    }];
    
    self.moneyLabel = [[UILabel alloc] init];
    self.moneyLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.moneyLabel.textColor = [UIColor colorWithHexString:@"#fa7f2b"];
    self.moneyLabel.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"¥%.2f",self.payMoney] withFont:16 type:1];
    [self.bottomView addSubview:self.moneyLabel];
    
    [self.moneyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.submitCourse.mas_left).offset(-8);
        make.centerY.mas_equalTo(self.submitCourse.mas_centerY);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    titleLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    titleLabel.text = NSLocalizedString(@"IN_TOTAL_PRICE", nil);
    [self.bottomView  addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.moneyLabel.mas_left).offset(-3);
        make.centerY.mas_equalTo(self.moneyLabel);
    }];
}

#pragma mark - 获取宝典数目
- (void)getLastCoupons {
    
    if (![self.baseTool networkingState]) {
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"apply_amount"] = @(self.payMoney);
    [params setValue:self.courseIds forKey:@"course_ids"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/get_user_coupon_info/",ELITEU_URL];
    
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self.remain_score = responseObject[@"data"][@"remain_score"]; //剩余宝典
        self.score_rate = responseObject[@"data"][@"score_rate"]; //购买课程最多使用宝典的比率
        
        NSArray *couponArray = responseObject[@"data"][@"coupon_list"];
        if (couponArray.count == 0) {
            self.isNoCoupon = YES;
        }
        [self.loadIngView removeFromSuperview];
        [self.tableView reloadData];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        [self.loadIngView removeFromSuperview];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 交学费
- (void)submitCoursesPayAction:(UIButton *)sender {
    
    if (![self.baseTool networkingState]) {
        return;
    }
    
    if (self.hideShowPurchase) {
        if (self.hadCreateOrder) {//已经点击过一次交学费 -- 处理微信支付宝左上角返回app
            [self gotoWaitForPayView];
            
        } else {
            if (self.payMoney > self.cutBaodian) {
                self.payMoney = self.cutBaodian;
            }
            
            if (self.payWay == 1) {
                [self createOrderWitType:1];
                return;
            }
            if (self.payWay == 2) {
                [self createOrderWitType:2];
            }
        }
        
    } else {
        self.payMoney = self.cutBaodian;
        [self payByBaodian];
    }
}

#pragma mark - 跳转到待支付
- (void)gotoWaitForPayView {
    WaitForPayViewController *waitForPayVC = [[WaitForPayViewController alloc] init];
    waitForPayVC.username = self.username;
    [self.navigationController pushViewController:waitForPayVC animated:YES];
}

#pragma mark - 未审核完成，用宝典支付
- (void)payByBaodian {
    NSString *messageStr = [Strings needCoinsWithCount:[NSString stringWithFormat:@"%.2f",[self.remain_score floatValue]] number:[NSString stringWithFormat:@"%.2f",self.payMoney * 10.0]];
    
    if ([self.remain_score floatValue] > self.payMoney * 10.0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SURE_TO_BUY", nil) message:messageStr delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        alert.tag = 1;
        [alert show];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO_ENOUGH_COINS", nil) message:messageStr delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"GO_TO_RECHARGE", nil), nil];
        alert.tag = 2;
        [alert show];
    }
}

#pragma mark - alertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == 1) {
            [self buyAction];
            
        } else {
            [self gotoRechargeView];
        }
    }
}
//用宝典购买
- (void)buyAction {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.courseIds forKey:@"course_ids"];
    [dic setValue:[NSString stringWithFormat:@"%.2lf",self.payMoney * 10.0] forKey:@"coin_num"];
    [dic setValue:[NSString stringWithFormat:@"%.2lf",self.payMoney] forKey:@"total_amount"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/finance/buy_course_by_coin/",ELITEU_URL];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success--payParams%@",responseObject);
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            [self.view makeToast:NSLocalizedString(@"BUY_SUCCESS", nil) duration:1.08 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [[OEXRouter sharedRouter] showMyCoursesAnimated:YES pushingCourseWithID:nil];//跳去我的课程页面
            });
            
        } else {
            NSLog(@"宝典购买------ %@ -----",responDic[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 跳去充值
- (void)gotoRechargeView {
    TDRechargeViewController *couViewController = [[TDRechargeViewController alloc] init];
    couViewController.currentCanons = [self.remain_score doubleValue];
    couViewController.username = self.username;
    
    WS(weakSelf);
    couViewController.rechargeSuccessHandle = ^(){
        [weakSelf getLastCoupons];
    };
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:couViewController animated:YES];
}

#pragma mark - 创建订单
- (void)createOrderWitType:(NSInteger)type {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.activity_id forKey:@"activity_id"];
    [dic setValue:self.coupon_id forKey:@"coupon_id"];
    [dic setValue:self.courseIds forKey:@"course_ids"];
    [dic setValue:self.usedcoin forKey:@"used_coin"];
    NSString *priceStr = [self.moneyLabel.text substringFromIndex:1];//总金额
    if ([priceStr floatValue] <= 0) {
        [self.view makeToast:NSLocalizedString(@"NO_LESSTHAN_ZERO", nil) duration:1.08 position:CSToastPositionCenter];
        return;
    }
    [dic setValue:priceStr forKey:@"apply_amount"];
    //    [dic setValue:[NSNumber numberWithFloat:self.payMoney] forKey:@"apply_amount"];
    
    if (type == 1) {//微信
        [dic setValue:@1 forKey:@"pay_method"];
    } else if (type == 2) {//支付宝
        [dic setValue:@2 forKey:@"pay_method"];
    }
    
    WS(weakSelf);
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/generate_prepaid_order_and_pay_for_course/",ELITEU_URL];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"创建订单成功--payParams%@",responseObject);
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            weakSelf.orderId = responseObject[@"data"][@"order_id"];
            weakSelf.hadCreateOrder = YES;
            
            if (type == 1) {
                self.weChatItem = [weChatParamsItem mj_objectWithKeyValues:responseObject[@"data"]];
                [self payByWeChat];
            } else if (type == 2) {
                _aliPayItem = [aliPayParamsItem mj_objectWithKeyValues:responseObject];
                [self payByAliPay];
            }
        
        } else {
            [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
            NSLog(@"--%@",responDic[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark ==微信支付
- (void)payByWeChat {
    [[[WeChatPay alloc] init] submitPostWechatPay:self.weChatItem];
}

#pragma mark - 支付宝支付
- (void)payByAliPay {
    
    Order *order = [[Order alloc] init];
    order.partner = _aliPayItem.data.data_url.partner;
    order.sellerID = _aliPayItem.data.data_url.seller_id;
    order.outTradeNO = _aliPayItem.data.data_url.out_trade_no; //订单ID（由商家自行制定）
    NSLog(@"order.outTradeNO--%@",order.outTradeNO);
    order.subject = _aliPayItem.data.data_url.subject; //商品标题
    order.body = _aliPayItem.data.data_url.body; //商品描述
    order.totalFee = _aliPayItem.data.data_url.total_fee;//商品价格
    order.notifyURL =  _aliPayItem.data.data_url.notify_url; //回调URL
    order.service = _aliPayItem.data.data_url.service;
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    //    order.itBPay = @"30m";
    //    order.showURL = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    //    NSString *appScheme = @"alisdkdemo";
    NSString *appScheme = @"org.eliteu.mobile";
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    //    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    //    NSString *signedString = [signer signString:orderSpec];
    
    NSString *base64String = _aliPayItem.data.data_url.sign;
    NSString *signedString = [self urlEncodedString:base64String];
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",orderSpec, signedString, @"RSA"];
        NSLog(@"orderString = %@",orderString);
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            //【callback处理支付结果】
            NSLog(@"A--reslut = %@",resultDic);
        }];
    }
}

- (NSString*)urlEncodedString:(NSString *)string {
    
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}

#pragma mark - 输入宝典弹窗
- (void)inputAlertShow {
    
    self.inputAlert = [[JHCouponsAlertView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.inputAlert.textF2.keyboardType = UIKeyboardTypeNumberPad;
    self.inputAlert.textF2.delegate = self;
    
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(backKeyBoards)];
    [self.inputAlert addGestureRecognizer:tapGesture];
    self.inputAlert.delegate = self;
    [self.inputAlert show];
    
    float score = [self.remain_score floatValue];
    float rate = [self.score_rate floatValue];
    
    NSString *currentStr = [NSString stringWithFormat:@"¥%.2f",self.payMoney];
    currentStr = [currentStr substringFromIndex:1];
    float currentM = [currentStr floatValue];
    int usedM = currentM * 10 * rate;
    
    if (score > usedM) {
        self.inputAlert.textF1.text = [Strings hadCoinsNumberWithCount:[NSString stringWithFormat:@"%.2f",score] number:[NSString stringWithFormat:@"%d.00",usedM]];
        _maxCoin = usedM;
        self.warmingStr = NSLocalizedString(@"MORE_COINS_REMAIND", nil);
        
    }  else{
        self.inputAlert.textF1.text = [Strings hadCoinsNumberWithCount:[NSString stringWithFormat:@"%.2f",score] number:[NSString stringWithFormat:@"%.2f",score]];
        _maxCoin = score;
        self.warmingStr = NSLocalizedString(@"MORE_COINS_AVALIDE", nil);
    }
}

#pragma mark - JHCouponsAlertViewDelegate
- (void)alertView:(JHCouponsAlertView *)alertView didSelectOptionButtonWithTag1:(NSInteger)btnTag{
    
    [self backKeyBoards];
    
    if (btnTag == 1) {
        float coin = [alertView.textF2.text floatValue];//输入的宝典数
        float currentM = self.payMoney;//合计金额
        
        if (coin > self.maxCoin) {//最多可用宝典
            
            alertView.textF2.text = nil;
            self.inputAlert.hidden = YES;
            
            [self.view makeToast:self.warmingStr duration:1.08 position:CSToastPositionCenter];
            
        } else {
            
            self.usedcoin = alertView.textF2.text;
            currentM -= 0.1 * coin;
//            self.moneyLabel.text = [NSString stringWithFormat:@"¥%.2f",currentM];
            self.moneyLabel.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"¥%.2f",currentM] withFont:16 type:1];
            self.cutBaodian = currentM;
            
            self.baodianStr = alertView.textF2.text;
            [self.tableView reloadData];
        }
    }
    
    self.inputAlert.hidden = YES;
    self.inputAlert = nil;
    self.view.userInteractionEnabled = YES;
    
    [self initialization];
}
//退回键盘
- (void)backKeyBoards{
    [[[UIApplication sharedApplication]keyWindow] endEditing:YES];
}

#pragma mark - 优惠券
- (void)gotoCoupon:(NSIndexPath *)indexPath {
    
    CouponsViewController *couponVc = [[CouponsViewController alloc] init];
    couponVc.username = _username;
    couponVc.apply_amount = self.totalM;
    couponVc.courseIds = self.courseIds;
    couponVc.couponName = self.couponStr;
    couponVc.selectCouponId = self.coupon_id;
    WS(weakSelf);
    couponVc.selectCouponHandle = ^(CouponsNameItem *model){
        [weakSelf selectCoupon:model withIndex:indexPath];
    };
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:couponVc animated:YES];
}

- (void)selectCoupon:(CouponsNameItem *)model withIndex:(NSIndexPath *)indexPath {

    self.couponStr = model.coupon_name;
    self.coupon_id = model.coupon_issue_id;
    self.isCampony = NO;
    
    if ([model.coupon_name isEqualToString:NSLocalizedString(@"SELECT_COUPON", nil)]) {//选择第一行
        self.payMoney = self.totalM;
        
    } else if ([model.coupon_type intValue] == 1) {//满减
        self.payMoney = self.totalM - [model.cutdown_price floatValue];
        
    } else if ([model.coupon_type intValue] == 2) {//满打折
        self.payMoney = self.totalM * [model.discount_rate floatValue];
        
    } else if ([model.coupon_type intValue] == 4) {//企业优惠券
        for (ChooseCourseItem *item in self.array0) {
            item.isCompanyCoupon = YES;
        }
        self.isCampony = YES;
        self.usedcoin = @"0";
        self.payMoney = [model.all_price floatValue] - [model.max_coupon_price floatValue] + [model.cutdown_price floatValue];
    }
    self.baodianStr = @"";
    [self.tableView reloadData];
//    self.moneyLabel.text = [NSString stringWithFormat:@"¥%.2f",self.payMoney];
    self.moneyLabel.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"¥%.2f",self.payMoney] withFont:16 type:1];
}

#pragma mark -- UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.hideShowPurchase ? 3 : 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return _array0.count;
    }
    if (section == 1) {
        return self.leftTielArray.count;
    }
    return self.payImgArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    if ([indexPath section] == 0) {
        WaitForPayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
        cell.chooseCourseItem = self.array0[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    } else if ([indexPath section] == 1){
        SubmiteSecondCell *cell = [[SubmiteSecondCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sumiteSecondCell"];
        cell.leftLabel.text = self.leftTielArray[indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == 0) {
            cell.rightLabel.text = self.isNoCoupon ? NSLocalizedString(@"NO_CHOOSE_COUPON", nil) : self.couponStr;
        } else {
            cell.rightLabel.text = self.baodianStr;
        }
        return cell;
        
    } else{
        
        PayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:payIdentify];
        cell.imgV1.image = [UIImage imageNamed:_payImgArr[indexPath.row]];
        cell.textL.text = _payImgArr1[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {//优惠券
            self.hideShowPurchase ? [self gotoCoupon:indexPath] : [self inputAlertShow];
            
        } else if (indexPath.row == 1) {
            if (!self.isCampony) {
                [self inputAlertShow];
            } else {
                [self.view makeToast:NSLocalizedString(@"COUPON_NO_COINS", nil) duration:1.08 position:CSToastPositionCenter];
            }
            
            if ([_first isEqual:[NSIndexPath indexPathForRow:0 inSection:2]]) {
                _first = [NSIndexPath indexPathForRow:0 inSection:2];
                [self.tableView selectRowAtIndexPath:_first animated:YES scrollPosition:UITableViewScrollPositionNone];
            }else{
                _first = [NSIndexPath indexPathForRow:1 inSection:2];
                [self.tableView selectRowAtIndexPath:_first animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            self.payWay = self.isWechatInstall ? 1 : 2;//微信
        }
        if (indexPath.row == 1) {
            self.payWay = 2;//支付宝
        }
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 2) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithHexString:@"#F5F7FA"];
        
        if (self.hideShowPurchase) {
            
            UILabel *title = [[UILabel alloc] init];
            title.text = NSLocalizedString(@"SELECT_PAYWAY", nil);
            title.font = [UIFont fontWithName:@"OpenSans" size:14];
            title.textAlignment = NSTextAlignmentCenter;
            title.textColor = [UIColor colorWithHexString:colorHexStr8];
            [view addSubview:title];
            [title mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerX.mas_equalTo(view.mas_centerX);
                make.centerY.mas_equalTo(view.mas_centerY);
            }];
            
            UILabel *line1 = [[UILabel alloc] init];
            line1.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
            [view addSubview:line1];
            [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.mas_equalTo(view.mas_centerY);
                make.left.mas_equalTo(view.mas_left);
                make.right.mas_equalTo(title.mas_left).offset(-8);
                make.height.mas_equalTo(1);
            }];
            
            UILabel *line2 = [[UILabel alloc] init];
            line2.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
            [view addSubview:line2];
            [line2 mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.mas_equalTo(view.mas_centerY);
                make.left.mas_equalTo(title.mas_right).offset(8);
                make.right.mas_equalTo(view.mas_right);
                make.height.mas_equalTo(1);
            }];
            
        }
        return view;
        
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        return view;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 120;
    }
    if (indexPath.section == 1) {
        return 46;
    } else if (indexPath.section == 2) {
        return !self.hideShowPurchase ? 0 : 60;
    }
    return 60;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 2) {
        return 48;
    }
    else return 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
