
//
//  WaitForPayViewController.m
//  edX
//
//  Created by Elite Edu on 16/10/17.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "WaitForPayViewController.h"
#import "TDBuySuccessViewController.h"
#import "OEXFlowErrorViewController.h"

#import "TDPayMoneyView.h"
#import "WechatPayView.h"
#import "AliPayView.h"
#import "WaitForPayTableViewCell.h"

#import "edX-Swift.h"
#import "PurchaseManager.h"
#import "TDBaseToolModel.h"
#import "OrderItem.h"
#import "SubOrderItem.h"
#import "Reachability.h"
#import "OEXAppDelegate.h"

#import <AFNetworking/AFNetworking.h>
#import <MJExtension/MJExtension.h>
#import <UIImageView+WebCache.h>

#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "DataSigner.h"
#import "WechatAuthSDK.h"
#import "weChatParamsItem.h"
#import "aliPayParamsItem.h"
#import "dataUrlItem.h"
#import "aliData.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import "Encryption.h"//md5加密
#import "WeChatPay.h"

@interface WaitForPayViewController ()<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

@property (nonatomic,strong) NSMutableArray *ordersArr;//所有的订单数组
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) UIView *payView;
@property (nonatomic,strong) UIView *topView;
@property (nonatomic,strong) WechatPayView *wechatView;
@property (nonatomic,strong) AliPayView *aliPayView;
@property (nonatomic,strong) NSString *sendOrdID;//选择的订单
@property (nonatomic,strong) weChatParamsItem *weChatItem;
@property (nonatomic,strong) aliPayParamsItem *aliPayItem;
@property (nonatomic,strong) NSString *orderMoney;//显示订单的价格
@property (nonatomic,assign) int payWay;//记录支付方式
@property (nonatomic,strong) NSString *orderId;

@property (nonatomic,strong) UIButton *returnButton;

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) BOOL hideShowPurchase;//0 为审核中；1 为审核通过
@property (nonatomic,strong) PurchaseManager *purchaseManager;

@end

static NSString *cellID = @"WaitForPayTableViewCell";

@implementation WaitForPayViewController

- (NSMutableArray *)ordersArr {
    if (!_ordersArr) {
        _ordersArr = [[NSMutableArray alloc] init];
    }
    return _ordersArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self requestData];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"WaitForPayTableViewCell" bundle:nil] forCellReuseIdentifier:cellID];
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    _payWay = 0;//默认微信支付方式
    
//    WS(weakSelf);
//    self.purchaseManager = [[PurchaseManager alloc] init];
//    self.purchaseManager.rqToUpStateHandle = ^(int state,NSString *receiveStr) {
//        
//        if (state == SKPaymentTransactionStatePurchased) {//成功
//            weakSelf.purchaseManager.purchaseModel.apple_receipt = receiveStr;
//            
//            [weakSelf.purchaseManager verificationAction:2];
//            
//            //保存订单信息和receipt在本地，做丢单处理
//            
//            
//        }else if (state == SKPaymentTransactionStatePurchasing) {
//            
//        } else if (state == SKPaymentTransactionStateFailed) {
//            
//        }
//    };
//    
//    self.purchaseManager.vertificationHandle = ^(id dataObject,NSString *tips){
//        
//        if ([tips isEqualToString:@"充值成功"]) {
//            [weakSelf.view makeToast:@"购买成功" duration:1.08 position:CSToastPositionCenter];
//            
//        } else {
//            //丢单处理
//        }
//        [weakSelf backButtonAction];
//    };
    
    [self setLoadDataView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paySuccess) name:@"aliPaySuccess" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.titleViewLabel.text = NSLocalizedString(@"PREPARE_PAY", nil);
    self.leftButton.hidden = YES;
    self.returnButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [self.returnButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    self.returnButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    self.returnButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    [self.returnButton addTarget:self action:@selector(returnButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    if (self.whereFrom == 1) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    } else {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ) {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
            self.navigationController.interactivePopGestureRecognizer.delegate = self;
        }
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.returnButton];
    
    //    WS(weakSelf);
    //    self.baseTool.judHidePurchseHandle = ^(BOOL isHidePurchase){
    //        weakSelf.hideShowPurchase = isHidePurchase;
    //    };
    //    [self.baseTool showPurchase];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self canclePayView];
}

- (void)returnButtonAction:(UIButton *)sender {
    if (self.whereFrom == 1) {
        [self.navigationController popToViewController:self.navigationController.childViewControllers[1] animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - 无数据
- (void)setNullDataBgView {
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    UILabel *nullLabel = [[UILabel alloc] init];
    nullLabel.text = NSLocalizedString(@"NO_COURSE_ORDER", nil);
    nullLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    nullLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    [bgView addSubview:nullLabel];
    [nullLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(bgView);
        make.centerY.mas_equalTo(bgView).offset(-18);
    }];
    
}
#pragma mark - 支付成功
- (void)backButtonAction {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - 支付成功
- (void)paySuccess {
    TDBuySuccessViewController *buySuccessVC = [[TDBuySuccessViewController alloc] init];
    buySuccessVC.orderId = self.orderId;
    NSLog(@"success %@ ====== %@",buySuccessVC.orderId,self.sendOrdID);
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:buySuccessVC animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPaySuccess" object:nil];
}

#pragma mark - 待支付订单
- (void)requestData{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/get_wait_order_list/",ELITEU_URL];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSArray * ary = (NSArray *)responseObject[@"data"];
        [self.ordersArr addObjectsFromArray:ary];
    
        if (self.ordersArr.count == 0) {
            [self setNullDataBgView];
        } else {
            [self.tableView reloadData];
        }
        [self.loadIngView removeFromSuperview];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadIngView removeFromSuperview];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 取消订单
- (void)cancelBtn:(UIButton *)btn{
    OrderItem * order = [OrderItem mj_objectWithKeyValues:self.ordersArr[btn.tag]];
    NSString *orderID = order.order_id;

    //会话管理者
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = _username;
    params[@"order_id"] = orderID;
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/cancel_wait_order/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *code = responseObject[@"code"];
        if ([code intValue] == 200){
            
            [self.ordersArr removeObjectAtIndex:btn.tag];
            [self.tableView reloadData];
            if (self.ordersArr.count == 0) {
                [self setNullDataBgView];
            }
            
        } else {
            NSLog(@"取消失败 --- %@",responseObject[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 支付按钮 -- 此处需要重构
- (void)payBtn:(UIButton *)sender {
    //订单号
    OrderItem *order = [OrderItem mj_objectWithKeyValues:self.ordersArr[sender.tag]];
    self.sendOrdID = order.order_id;
    self.orderMoney = order.real_amount;
    
    NSLog(@"send %@  ----->order %@",self.sendOrdID,order.order_id);

    if (self.hideShowPurchase) {
        [self paySheetView:order];
    } else {
        [self createOrderWithType:3];
    }
}

#pragma mark - 点击支付
- (void)orderPayBtn {
    [self canclePayView];
    
    if (_payWay == 0) {
        [self createOrderWithType:1];
    }
    if (_payWay == 1) {
        [self createOrderWithType:2];
    }
}

#pragma mark - 创建订单
- (void)createOrderWithType:(NSInteger)type {//1 微信支付；2 支付宝支付
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.sendOrdID forKey:@"order_id"];
    
    if (type == 1) {
        [dic setValue:@1 forKey:@"pay_method"];
    } else if (type == 2) {
        [dic setValue:@2 forKey:@"pay_method"];
    } else if (type == 3) {
        [dic setValue:@5 forKey:@"pay_method"];
    }
    
//    WS(weakSelf);
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/get_pay_course_info/",ELITEU_URL];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            self.orderId = responseDic[@"data"][@"order_id"];
            if (type == 1) {
                _weChatItem = [weChatParamsItem mj_objectWithKeyValues:responseObject[@"data"]];
                [self wechatPay];
                
            } else if (type == 2) {
                _aliPayItem = [aliPayParamsItem mj_objectWithKeyValues:responseObject];
                [self aliPay];
            } else if (type == 3) {
                //            NSString *rechargeMoney = responseObject[@"data"][@"apply_amount"];
                //            weakSelf.purchaseManager.purchaseModel.total_fee = [NSString stringWithFormat:@"%@",rechargeMoney];
                //
                //            weakSelf.purchaseManager.purchaseModel.userName = self.username;
                //            weakSelf.purchaseManager.purchaseModel.trader_num = responseObject[@"data"][@"order_id"];
                //            
                //            [weakSelf rqPayByApple:rechargeMoney];
            }
        } else {
            NSLog(@"创建订单 === 》  %@",responseDic[@"msg"]);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:@"网络忙，请重试！" duration:1.08 position:CSToastPositionCenter];
        NSLog(@"error--%@",error);
    }];
}

- (void)rqPayByApple:(NSString *)rechargeMoney {
    int totalMoney = [rechargeMoney intValue];
    
    int payType = 1;
    if (totalMoney <= 100) {
        payType = 1;
    } else if (totalMoney <= 200 && totalMoney > 100){
        payType = 2;
    } else if (totalMoney <= 300 && totalMoney > 200) {
        payType = 3;
    } else if (totalMoney <= 500 && totalMoney > 300) {
        payType = 4;
    } else if (totalMoney <= 500 && totalMoney > 300) {
        payType = 5;
    }else {
        payType = 6;
    }
    
    [self.purchaseManager reqToUpMoneyFromApple:payType];
}

#pragma mark - 调起微信支付
- (void)wechatPay {
    
    [[[WeChatPay alloc] init] submitPostWechatPay:self.weChatItem];
}

#pragma mark - 调起支付宝
- (NSString*)urlEncodedString:(NSString *)string
{
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}
- (void)aliPay{
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

#pragma mark - 选择支付方式
- (void)tap1{
    //设置选择状态
    _wechatView.imgV.image = [UIImage imageNamed:@"selected"];
    _aliPayView.imgV.image = [UIImage imageNamed:@"selectedNo"];
    _payWay = 0;
}
- (void)tap2{
    //设置选择状态
    _wechatView.imgV.image = [UIImage imageNamed:@"selectedNo"];
    _aliPayView.imgV.image = [UIImage imageNamed:@"selected"];
    _payWay = 1;
}
- (void)canclePayView{//点击取消
    [UIView animateWithDuration:2.0 animations:^{
        [self.payView removeFromSuperview];
    }];
}
#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.ordersArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OrderItem * order = [OrderItem mj_objectWithKeyValues:self.ordersArr[section]];
    return order.order_items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    tableView.separatorInset = UIEdgeInsetsMake(0, -10, 0, 0);
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    WaitForPayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    OrderItem *order = [OrderItem mj_objectWithKeyValues:self.ordersArr[indexPath.section]];
    
    NSArray * orderary1 = order.order_items;
    SubOrderItem * subord = [SubOrderItem mj_objectWithKeyValues:orderary1[indexPath.row]];
    cell.courseNameL.text = subord.display_name;
    cell.professorL.text = subord.teacher_name;
    NSString *string1 = [NSString stringWithFormat:@"%@%@",ELITEU_URL,subord.image];
    NSString* string2 = [string1 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [cell.imgV sd_setImageWithURL:[NSURL URLWithString:string2] placeholderImage:[UIImage imageNamed:@"Shape"]];
    
    NSString *maxStr = [NSString stringWithFormat:@"￥%.2f",[subord.price floatValue]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.min_pricelL.attributedText = [self.baseTool setString:maxStr withFont:16  type:1];
    cell.max_priceL.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%.2f",[subord.min_price floatValue]] withFont:12 type:2];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 67;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    OrderItem * order = [OrderItem mj_objectWithKeyValues:self.ordersArr[section]];
    return [order.give_coin floatValue] > 0 ? 160 : 110;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    OrderItem * order = [OrderItem mj_objectWithKeyValues:self.ordersArr[section]];
    return [self setHeaderViewWithOrder:order forSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    OrderItem *order = [OrderItem mj_objectWithKeyValues:self.ordersArr[section]];
    return [self setFootViewWithOrder:order forSection:section];
}

#pragma mark - 头部视图
- (UIView *)setHeaderViewWithOrder:(OrderItem *)order forSection:(NSInteger)section {
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    UIView *orderView = [UIView new];
    orderView.backgroundColor = [UIColor whiteColor];
    [view addSubview:orderView];
    [orderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.mas_equalTo(view);
        make.top.mas_equalTo(view.mas_top).offset(18);
        make.width.mas_equalTo(TDWidth);
    }];
    
    //单号
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14];
    label.text = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"ORDER_NUMBER", nil),order.order_id];
    label.textColor = [UIColor colorWithHexString:colorHexStr10];
    [orderView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(orderView.mas_left).offset(13);
        make.centerY.mas_equalTo(orderView.mas_centerY).offset(0);
    }];
    
    //取消
    UIButton *cancleButton = [[UIButton alloc] init];
    [cancleButton setTitle:NSLocalizedString(@"CANCEL", nil) forState:UIControlStateNormal];
    [cancleButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [cancleButton setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(cancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    cancleButton.tag = section;
    [orderView addSubview:cancleButton];
    
    [cancleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(orderView.mas_right).offset(0);
        make.centerY.mas_equalTo(label);
        make.size.mas_equalTo(CGSizeMake(60, 30));
    }];
    
    return view;
}

#pragma mark - 底部视图
- (UIView *)setFootViewWithOrder:(OrderItem *)order forSection:(NSInteger)section {
    
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor whiteColor];
    
    NSMutableAttributedString *str1 = [self.baseTool setString:[NSString stringWithFormat:@"%@:-¥%.2f",NSLocalizedString(@"COUPON_ACTIVITY", nil),[order.activate_price floatValue]] withFont:12 type:1];
    NSMutableAttributedString *str2 = [self.baseTool setString:[NSString stringWithFormat:@"  %@:-¥%.2f",NSLocalizedString(@"COUPON_PAPER", nil),[order.coupon_amount floatValue]] withFont:12 type:1];
    NSMutableAttributedString *str3 = [self.baseTool setString:[NSString stringWithFormat:@"  %@:-¥%.2f",NSLocalizedString(@"COINS_VALUE", nil),[order.cost_coin floatValue] / 10.0] withFont:12 type:1];
    [str1 appendAttributedString:str2];
    [str1 appendAttributedString:str3];
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    messageLabel.numberOfLines = 0;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    messageLabel.attributedText = str1;
    [view addSubview:messageLabel];
    
    [messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(view.mas_left).offset(13);
        make.top.mas_equalTo(view.mas_top).offset(0);
        make.height.mas_equalTo(49);
        make.right.mas_equalTo(view.mas_right).offset(-8);
    }];
    
    UIView *line = [[UIView alloc] init];//分割线
    line.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [view addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(0.5);
        make.top.mas_equalTo(messageLabel.mas_bottom).offset(0);
    }];
    
    UIButton *payBttuon = [[UIButton alloc] init];
    payBttuon.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    payBttuon.layer.cornerRadius = 4.0;
    payBttuon.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    payBttuon.tag = section;
    [payBttuon setTitle:NSLocalizedString(@"PAY_TITLE", nil) forState:UIControlStateNormal];
    [payBttuon addTarget:self action:@selector(payBtn:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:payBttuon];
    
    [payBttuon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(view.mas_right).offset(-13);
        make.top.mas_equalTo(line.mas_bottom).offset(8);
        make.size.mas_equalTo(CGSizeMake(105, 40));
    }];
    
    if ([order.give_coin floatValue] > 0) {
        
        NSMutableString *str1 = [[NSMutableString alloc] initWithString:order.end_at];
        NSMutableString *str2 = [[NSMutableString alloc] initWithString:order.begin_at];
        NSString *mindStr = [Strings payReceiveMindWithStartdate:[str2 substringToIndex:10] enddate:[str1 substringToIndex:10] number:[NSString stringWithFormat:@"%.2f",[order.give_coin floatValue]]];

        
        UILabel *giftLabel = [[UILabel alloc] init];
        giftLabel.numberOfLines = 0;
        giftLabel.textAlignment = NSTextAlignmentCenter;
        giftLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        giftLabel.attributedText = [self.baseTool setDetailString:mindStr withFont:12 withColorStr:colorHexStr4];
        [view addSubview:giftLabel];
        
        [giftLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(view.mas_left).offset(13);
            make.right.mas_equalTo(view.mas_right).offset(-8);
            make.top.mas_equalTo(line.mas_bottom).offset(0);
            make.height.mas_equalTo(49);
        }];
        
        UIView *line1 = [[UIView alloc] init];//分割线
        line1.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [view addSubview:line1];
        [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(0);
            make.height.mas_equalTo(0.5);
            make.top.mas_equalTo(giftLabel.mas_bottom).offset(0);
        }];
        
        [payBttuon mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(view.mas_right).offset(-13);
            make.top.mas_equalTo(line1.mas_bottom).offset(8);
            make.size.mas_equalTo(CGSizeMake(105, 40));
        }];
    }
    
    UILabel *realMoney = [[UILabel alloc] init];
    realMoney.font = [UIFont systemFontOfSize:14];
    realMoney.attributedText = [self setRealMoney:[NSString stringWithFormat:@"￥%.2f",[order.real_amount floatValue]]];
    [view addSubview:realMoney];
    [realMoney mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(payBttuon.mas_left).offset(-8);
        make.centerY.mas_equalTo(payBttuon.mas_centerY);
    }];
    
    return view;
}

- (NSMutableAttributedString *)setRealMoney:(NSString *)moneyStr {
    
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"IN_TOTAL_PRICE", nil) attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr9]}];
    NSMutableAttributedString *str2 = [self.baseTool setDetailString:moneyStr withFont:14 withColorStr:@"#fa7f2b"];
    [str1 appendAttributedString:str2];
    return str1;
}

#pragma mark - 支付页面
- (void)paySheetView:(OrderItem *)order {
    
//    BOOL hasWechat = [WXApi isWXAppInstalled];
    BOOL hasWechat = YES;
    //布局子控件
    CGFloat alertHeight = 228;
    
    UIView *payView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, TDHeight)];
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    [window addSubview:payView];
    
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, TDHeight)];
    topView.backgroundColor = [UIColor blackColor];
    topView.alpha = 0.5;
    [payView addSubview:topView];
    
    
    UIView *bottomV = [[UIView alloc] initWithFrame:CGRectMake(0, TDHeight, TDWidth, alertHeight)];
    bottomV.backgroundColor = [UIColor whiteColor];
    [payView addSubview: bottomV];
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    [bottomV addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(bottomV.mas_top).offset(0);
        make.height.mas_equalTo(60);
        make.left.right.mas_equalTo(bottomV);
    }];
    
    UILabel *title = [[UILabel alloc] init];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:@"OpenSans" size:14];
    title.text = NSLocalizedString(@"SELECT_PAYWAY", nil);
    title.textColor = [UIColor colorWithHexString:colorHexStr9];
    [bgView addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bgView.mas_centerY);
        make.centerX.mas_equalTo(bgView.mas_centerX);
    }];
    
    UILabel *line1 = [[UILabel alloc] init];
    line1.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [bgView addSubview:line1];
    [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bgView.mas_centerY);
        make.left.mas_equalTo(bgView.mas_left);
        make.right.mas_equalTo(title.mas_left).offset(-8);
        make.height.mas_equalTo(1);
    }];
    
    UILabel *line2 = [[UILabel alloc] init];
    line2.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [bgView addSubview:line2];
    [line2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(bgView.mas_centerY);
        make.right.mas_equalTo(bgView.mas_right);
        make.left.mas_equalTo(title.mas_right).offset(8);
        make.height.mas_equalTo(1);
    }];
    
    self.payView = payView;
    self.topView = topView;
    
    UITapGestureRecognizer *tapView= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(canclePayView)];
    [self.topView addGestureRecognizer:tapView];
    
    //微信
    WechatPayView *wechatView = [WechatPayView initView];
    wechatView.titleLabel.text = NSLocalizedString(@"WECHAT_PAY", nil);
    if (hasWechat) {
        wechatView.backgroundColor = [UIColor colorWithHexString:@"#f5f7fa"];
        wechatView.line.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [bottomV addSubview:wechatView];
        [wechatView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(bottomV.mas_top).offset(60);
            make.left.mas_equalTo(bottomV);
            make.size.mas_equalTo(CGSizeMake(TDWidth, 60));
        }];
    }
     _wechatView = wechatView;
    
    //支付宝
    AliPayView *aliPayView = [AliPayView initView];
    aliPayView.backgroundColor = [UIColor colorWithHexString:@"#f5f7fa"];
    aliPayView.titleLabel.text = NSLocalizedString(@"ALI_PAY", nil);
    [bottomV addSubview:aliPayView];
    [aliPayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(bottomV);
        hasWechat ? make.top.mas_equalTo(wechatView.mas_bottom).offset(0) : make.top.mas_equalTo(bottomV.mas_top).offset(60);
        make.size.mas_equalTo(CGSizeMake(TDWidth, 60));
    }];
    
    TDPayMoneyView *payMoneyView = [[TDPayMoneyView alloc] init];
    payMoneyView.moneyLabel.attributedText = [self setRealMoney:[NSString stringWithFormat:@"¥%.2f",[self.orderMoney floatValue]]];//订单价格
    [payMoneyView.payButton addTarget:self action:@selector(orderPayBtn) forControlEvents:UIControlEventTouchUpInside];//支付按钮
    [bottomV addSubview:payMoneyView];
    
    [payMoneyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(bottomV);
        make.bottom.mas_equalTo(bottomV.mas_bottom).offset(0);
        make.height.mas_equalTo(48);
    }];
    
    self.aliPayView = aliPayView;
    if ( hasWechat) {
        [self tap1];
    } else{
        [self tap2];
    }
    
    
    UITapGestureRecognizer *tap1= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap1)];
    UITapGestureRecognizer *tap2= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap2)];
    
    [self.wechatView addGestureRecognizer:tap1];
    [self.aliPayView addGestureRecognizer:tap2];
    
    //平移动画
    [UIView animateWithDuration:0.3 animations:^{
        bottomV.frame = CGRectMake(0, TDHeight - alertHeight, TDWidth, alertHeight);
    }];
    
    if ([order.give_coin floatValue] > 0) {
        NSString *coinStr = [Strings giveCoinsNumberWithCount:[NSString stringWithFormat:@"%.2f",[order.give_coin floatValue]]];
        NSMutableAttributedString *str4 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"PAY_TITLE", nil)] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],NSForegroundColorAttributeName : [UIColor whiteColor]}];
        NSMutableAttributedString *str5 = [self.baseTool setDetailString:coinStr withFont:11 withColorStr:colorHexStr3];
        [str4 appendAttributedString:str5];
        [payMoneyView.payButton setAttributedTitle:str4 forState:UIControlStateNormal];
    }
}



- (void)hiddenIndicator{
    //    self.indicator.hidden = YES;
    //    self.view.userInteractionEnabled = YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
