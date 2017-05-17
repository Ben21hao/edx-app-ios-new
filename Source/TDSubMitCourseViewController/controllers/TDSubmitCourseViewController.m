//
//  TDSubmitCourseViewController.m
//  edX
//
//  Created by Ben on 2017/5/2.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDSubmitCourseViewController.h"
#import "SubmiteSecondCell.h"
#import "TDWaitforPayCell.h"
#import "TDSelectPayCell.h"

#import "CouponsNameItem.h"

#import "CouponsViewController.h"
#import "TDBuySuccessViewController.h"
#import "JHCouponsAlertView.h"

#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"

#import "aliPayParamsItem.h"
#import "DataSigner.h"
#import "dataUrlItem.h"
#import "aliData.h"

#import "TDAliPayModel.h"
#import "TDAlipay.h"

#import "weChatParamsItem.h"
#import "WeChatPay.h"
#import "WXApi.h"

#import "Encryption.h"//md5加密

#import <MJExtension/MJExtension.h>
#import "edX-Swift.h"

@interface TDSubmitCourseViewController () <UITableViewDelegate,UITableViewDataSource,JHCouponsAlertViewDelegate,UIAlertViewDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UILabel *moneyLabel;
@property (nonatomic,strong) UIButton *backButton;

@property (nonatomic,strong) JHCouponsAlertView *inputAlert;

@property (nonatomic,strong) NSArray *leftTielArray;

@property (nonatomic,strong) NSMutableArray *payArray; //支付方式
@property (nonatomic,assign) NSInteger payType; // 0 : 微信 , 1 : 支付宝

@property (nonatomic,strong) NSString *couponStr;
@property (nonatomic,strong) NSString *baodianStr;
@property (nonatomic,strong) NSString *warmingStr;

@property (nonatomic,assign) float payMoney;
@property (nonatomic,assign) float cutBaodian;
@property (nonatomic,strong) NSString *usedcoin;
@property (nonatomic,assign) float maxCoin;//最多可用宝典
@property (nonatomic,strong) NSNumber *remain_score;
@property (nonatomic,strong) NSString *score_rate;

@property (nonatomic,strong) NSString *orderId;
@property (nonatomic,strong) NSString *courseIds;//拼接所有课程id
@property (nonatomic,strong) NSString *coupon_id;//优惠券id
@property (nonatomic,strong) NSMutableArray *courseIdArray;

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) BOOL isNoCoupon;
@property (nonatomic,assign) BOOL isCampony;
@property (nonatomic,assign) BOOL hadCreateOrder;//是否已创建订单

@property (nonatomic,strong) weChatParamsItem *weChatItem;
@property (nonatomic,strong) aliPayParamsItem *aliPayItem;
@property (nonatomic,strong) TDAliPayModel *aliPayModel;

@end

@implementation TDSubmitCourseViewController
- (NSMutableArray *)payArray {
    if (!_payArray) {
        _payArray = [[NSMutableArray alloc] init];
    }
    return _payArray;
}
- (NSMutableArray *)courseIdArray {
    if (!_courseIdArray) {
        _courseIdArray = [[NSMutableArray alloc] init];
    }
    return _courseIdArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    
     [self setLoadDataView];
    [self configData];
    [self setViewConstraint];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"aliPaySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backButtonNotiAction) name:@"aliPayFail" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPaySuccess" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPayFail" object:nil];
}

- (void)paySuccess {
    TDBuySuccessViewController *buySuccessVC = [[TDBuySuccessViewController alloc] init];
    buySuccessVC.orderId = self.orderId;
    NSLog(@"success %@ ",buySuccessVC.orderId);
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:buySuccessVC animated:YES];
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
        [self.loadIngView removeFromSuperview];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 提交
- (void)submitButtonAction:(UIButton *)sender {
    
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
            
            if (self.payType == 0) {
                [self createOrderWitType:1];
                return;
            } else {
                [self createOrderWitType:2];
            }
        }
        
    } else {
        self.payMoney = self.cutBaodian;
        [self payByBaodian];
    }
}

- (void)gotoWaitForPayView { //待支付
    WaitForPayViewController *waitForPayVC = [[WaitForPayViewController alloc] init];
    waitForPayVC.username = self.username;
    [self.navigationController pushViewController:waitForPayVC animated:YES];
}

- (void)payByBaodian { //未审核完成，用宝典支付
    
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == 1) {
            [self buyByCoinAction];
        } else {
            [self gotoRechargeView];
        }
    }
}

- (void)buyByCoinAction { //用宝典购买
    
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
        NSLog(@"error--%@",error);
    }];
}

- (void)gotoRechargeView {//跳去充值
    
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
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"SUBMIT_ING", nil)];
    SVProgressHUD.defaultMaskType = SVProgressHUDMaskTypeBlack;
    SVProgressHUD.defaultStyle = SVProgressHUDAnimationTypeNative;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/JavaScript",@"text/html",@"text/plain", nil];
    
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
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            weakSelf.orderId = responseDic[@"data"][@"order_id"];
            weakSelf.hadCreateOrder = YES;
            
            if (type == 1) {
                self.weChatItem = [weChatParamsItem mj_objectWithKeyValues:responseDic[@"data"]];
                [self payByWeChat];
                
            } else if (type == 2) {
                _aliPayItem = [aliPayParamsItem mj_objectWithKeyValues:responseDic];
                [self payByAliPay];
                
//                self.aliPayModel = [TDAliPayModel mj_objectWithKeyValues:responseDic[@"data"][@"data_url"]];
//                [self submitByAlipay];
            }
            
        } else {
            [self.view makeToast:NSLocalizedString(@"PAY_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
            NSLog(@"--%@",responseDic[@"msg"]);
        }
        [SVProgressHUD dismiss];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark ==微信支付
- (void)payByWeChat {
    [[[WeChatPay alloc] init] submitPostWechatPay:self.weChatItem];
}

#pragma mark - 支付宝支付
- (void)submitByAlipay {
    [[[TDAlipay alloc] init] submitPostAliPay:self.aliPayModel];
}

- (void)payByAliPay {
    
    Order *order = [[Order alloc] init];
    order.partner = _aliPayItem.data.data_url.partner;
    order.sellerID = _aliPayItem.data.data_url.seller_id;
    order.outTradeNO = _aliPayItem.data.data_url.out_trade_no; //订单ID（由商家自行制定）
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
    NSString *appScheme = @"org.eliteu.mobile-person";
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
        self.payMoney = [model.all_price floatValue] - [model.max_coupon_price floatValue] + [model.cutdown_price floatValue];
    }
    self.usedcoin = @"0";
    self.baodianStr = @"";
    [self.tableView reloadData];
    self.self.moneyLabel.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"¥%.2f",self.payMoney] withFont:16 type:1];
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
        self.maxCoin = usedM;
        self.warmingStr = NSLocalizedString(@"MORE_COINS_REMAIND", nil);
        
    }  else{
        self.inputAlert.textF1.text = [Strings hadCoinsNumberWithCount:[NSString stringWithFormat:@"%.2f",score] number:[NSString stringWithFormat:@"%.2f",score]];
        self.maxCoin = score;
        self.warmingStr = NSLocalizedString(@"MORE_COINS_AVALIDE", nil);
    }
}

#pragma mark - JHCouponsAlertViewDelegate
- (void)alertView:(JHCouponsAlertView *)alertView didSelectOptionButtonWithTag1:(NSInteger)btnTag {
    
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
}

- (void)backKeyBoards {//退回键盘
    [[[UIApplication sharedApplication]keyWindow] endEditing:YES];
}

#pragma mark - 初始化数据
- (void)configData {
    
    if (self.coupon_id == nil) {
        _coupon_id = @"0";
    }
    if (self.activity_id == nil) {
        self.activity_id = @"0";
    }
    if (self.usedcoin == nil) {
        self.usedcoin = @"0";
    }
    for (ChooseCourseItem *courseItem in self.array0) {
        [self.courseIdArray addObject:courseItem.course_id];
    }
    self.courseIds = [self.courseIdArray componentsJoinedByString:@","];
    
    self.isNoCoupon = NO;
    self.isCampony = NO;
    self.hadCreateOrder = NO;
    self.payMoney = self.totalM;
    self.cutBaodian = self.totalM;
    
    self.couponStr = NSLocalizedString(@"SELECT_COUPON", nil);
    
    self.leftTielArray = self.hideShowPurchase ? @[NSLocalizedString(@"COUPON_PAPER", nil),NSLocalizedString(@"COINS_VALUE", nil)] : @[];
    
    
    int selectWX = [WXApi isWXAppInstalled] ? 0 : 1;
    NSDictionary *dic1 = [NSDictionary dictionaryWithObjectsAndKeys:@"weChat",@"imageStr",NSLocalizedString(@"WECHAT_PAY", nil),@"payStr", @(1),@"isSelected",@"0",@"payType",nil];
    NSDictionary *dic2 = [NSDictionary dictionaryWithObjectsAndKeys:@"zhifu",@"imageStr",NSLocalizedString(@"ALI_PAY", nil),@"payStr", @(selectWX),@"isSelected",@"1",@"payType",nil];
    
    if ([WXApi isWXAppInstalled]) {
        self.payType = 0;
        [self dicChangeToModel:dic1];
    } else {
        self.payType = 1;
    }
    [self dicChangeToModel:dic2];
    
    [self getLastCoupons];//获得剩余宝典
}

- (void)dicChangeToModel:(NSDictionary *)dic {//转为model
    
    TDSelectPayModel *model = [TDSelectPayModel mj_objectWithKeyValues:dic];
    if (model) {
        [self.payArray addObject:model];
    }
}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.hideShowPurchase ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.array0.count;
    }
    if (section == 1) {
        return self.leftTielArray.count;
    }
    return self.payArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    if ([indexPath section] == 0) {
        TDWaitforPayCell *cell = [[TDWaitforPayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDWaitforCell"];
        cell.model = self.array0[indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    } else if ([indexPath section] == 1){
        
        SubmiteSecondCell *cell = [[SubmiteSecondCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDSumiteSecondCell"];
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
        TDSelectPayModel *model = self.payArray[indexPath.row];
        TDSelectPayCell *cell = [[TDSelectPayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDSelectPayCell"];
        cell.payModel = model;
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
        }
    } else if (indexPath.section == 2) {
        
        TDSelectPayModel *model1 = self.payArray[indexPath.row];
        model1.isSelected = YES;
        self.payType = [model1.payType intValue];
        
        if (self.payArray.count == 2) {
            if (indexPath.row == 0) {
                TDSelectPayModel *model1 = self.payArray[1];
                model1.isSelected = NO;
            } else {
                TDSelectPayModel *model0 = self.payArray[0];
                model0.isSelected = NO;
            }
        }
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
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


#pragma mark - UI
- (void)setViewConstraint {
    
    CGFloat height = 44;
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(height);
    }];
    
    UIView *bottomView = [[UIView alloc] init];
    bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomView];
    
    [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.height.mas_equalTo(height);
    }];
    
    UIButton *submitButton = [[UIButton alloc] init];
    submitButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    submitButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    submitButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    submitButton.titleLabel.numberOfLines = 0;
    [submitButton addTarget:self action:@selector(submitButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [submitButton setTitle:NSLocalizedString(@"HAND_MONEY", nil) forState:UIControlStateNormal];
    [bottomView addSubview:submitButton];
    
    if ([self.giftCoin floatValue] > 0) {
        NSString *coinNumStr = [Strings giveCoinsNumberWithCount:self.giftCoin];
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"HAND_MONEY", nil)] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],NSForegroundColorAttributeName : [UIColor whiteColor]}];
        NSMutableAttributedString *str2 = [self.baseTool setDetailString:coinNumStr withFont:11 withColorStr:colorHexStr3];
        [str1 appendAttributedString:str2];
        [submitButton setAttributedTitle:str1 forState:UIControlStateNormal];
    }
    
    [submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.mas_equalTo(bottomView);
        make.width.mas_equalTo(99);
    }];
    
    self.moneyLabel = [[UILabel alloc] init];
    self.moneyLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.moneyLabel.textColor = [UIColor colorWithHexString:@"#fa7f2b"];
    self.moneyLabel.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"¥%.2f",self.payMoney] withFont:16 type:1];
    [bottomView addSubview:self.moneyLabel];
    
    [self.moneyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(submitButton.mas_left).offset(-8);
        make.centerY.mas_equalTo(submitButton.mas_centerY);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    titleLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    titleLabel.text = NSLocalizedString(@"IN_TOTAL_PRICE", nil);
    [bottomView  addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.moneyLabel.mas_left).offset(-3);
        make.centerY.mas_equalTo(self.moneyLabel);
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
