//
//  TDRechargeViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/4.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDRechargeViewController.h"
#import "TDRechargeSuccessViewController.h"

#import "TDSelectPayCell.h"
#import "TDSelectPayModel.h"
#import "TDRechargeView.h"
#import "TDBaseToolModel.h"

#import "PurchaseManager.h"

#import "weChatParamsItem.h"
#import "WeChatPay.h"
#import "WXApi.h"

#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"
#import "TDAliPayModel.h"
#import "TDAlipay.h"

#import "edX-Swift.h"
#import <MJExtension/MJExtension.h>

@interface TDRechargeViewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (nonatomic,strong) TDRechargeView *rechargeView;
@property (nonatomic,strong) NSMutableArray *payArray; //支付方式
@property (nonatomic,strong) NSArray *moneyArray; //充值金额数组
@property (nonatomic,strong) NSString *exchangeRate;//转化率
@property (nonatomic,strong) NSString *rechargeMoney;//充值金额
@property (nonatomic,assign) NSInteger payType; // 0 : 微信 , 1 : 支付宝
@property (nonatomic,strong) NSString *orderId; //订单ID

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) BOOL isHidePurchase; //是否隐藏内购

@property (nonatomic,strong) PurchaseManager *purchaseManager;//内购工具类
@property (nonatomic,assign) BOOL isPurchassing; //正在进行内购

@property (nonatomic,strong) weChatParamsItem *weChatItem;
@property (nonatomic,strong) TDAliPayModel *aliPayModel;

@end

@implementation TDRechargeViewController

- (NSMutableArray *)payArray {
    if (!_payArray) {
        _payArray = [[NSMutableArray alloc] init];
    }
    return _payArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setLoadDataView];
    
    WS(weakSelf);
    self.baseTool = [[TDBaseToolModel alloc] init];
    self.baseTool.judHidePurchseHandle = ^(BOOL isHidePurchase){
        weakSelf.isHidePurchase = isHidePurchase;
//        weakSelf.isHidePurchase = NO;
        [weakSelf requestMoneyData]; //按钮金额
    };
    [self.baseTool showPurchase];
    
    self.isPurchassing = NO;
    self.purchaseManager = [[PurchaseManager alloc] init];
    self.purchaseManager.rqToUpStateHandle = ^(int state,NSString *receiveStr) {
        
        if (state == SKPaymentTransactionStatePurchased) {//成功
            weakSelf.purchaseManager.purchaseModel.apple_receipt = receiveStr;
            
            [weakSelf.purchaseManager verificationAction:1];
            
        //TODO:保存订单信息和receipt在本地，做丢单处理
        }else if (state == SKPaymentTransactionStatePurchasing) {
            
        } else if (state == SKPaymentTransactionStateFailed) {
            weakSelf.isPurchassing = NO;
            [SVProgressHUD dismiss];
        }
    };
    
    self.purchaseManager.vertificationHandle = ^(id dataObject,NSString *tips){
        if ([tips isEqualToString:NSLocalizedString(@"RECHARGE_SUCCESS", nil)]) {
            [weakSelf.view makeToast:NSLocalizedString(@"RECHARGE_SUCCESS", nil) duration:1.08 position:CSToastPositionCenter];
            [weakSelf successPay];
            
        } else {
            //TODO:丢单处理
        }
        weakSelf.isPurchassing = NO;
        [SVProgressHUD dismiss];
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successPay) name:@"aliPaySuccess" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"RECHARGE_Coins", nil);
    [self.leftButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"aliPaySuccess" object:nil];
}

#pragma mark - 充值成功
- (void)successPay {
    
    if (self.rechargeSuccessHandle) {
        self.rechargeSuccessHandle();
    }
    
    TDRechargeSuccessViewController *successVC = [[TDRechargeSuccessViewController alloc] init];
    successVC.orderId = self.orderId;
    WS(weakSelf);
    successVC.updateTotalCoinHandle = ^(NSString *totalStr){
            weakSelf.rechargeView.topLabel.attributedText = [self.baseTool setDetailString:[NSString stringWithFormat:@"%@ %.2f)",NSLocalizedString(@"CURRENT_COINS", nil),[totalStr floatValue]] withFont:14 withColorStr:colorHexStr8];
    };
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:successVC animated:YES];
}

#pragma mark -- 请求充值金额
- (void)requestMoneyData {
    
    if (![self.baseTool networkingState]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"username"] = self.username;
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/finance/give_coin/",ELITEU_URL];
    
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            self.moneyArray = responDic[@"data"][@"apply_amount"];
            self.exchangeRate = responDic[@"data"][@"total_coin_rate"];
            self.currentCanons = [responDic[@"data"][@"remain_score"] doubleValue];
            
        } else if ([code intValue] == 404) {
            [self.view makeToast:NSLocalizedString(@"NO_EXIST_USER", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
        if (self.moneyArray.count > 0) {
            [self setUpView];//页面UI
        }
        [self.loadIngView removeFromSuperview];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadIngView removeFromSuperview];
        NSLog(@"error -- %@",error);
    }];
}

#pragma mark - UI
- (void)setUpView {
    
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
    
    [self setViewConstraint:self.isHidePurchase ? 1 : 2]; //UI
}

- (void)setViewConstraint:(NSInteger)type {
    self.rechargeView = [[TDRechargeView alloc] initWithType:type]; //type: 1 审核通过，2 审核中
    [self.rechargeView setMoneyViewData:self.moneyArray withType:1];
    self.rechargeView.topLabel.attributedText = [self.baseTool setDetailString:[NSString stringWithFormat:@"%@ %.2f)",NSLocalizedString(@"CURRENT_COINS", nil),self.currentCanons] withFont:14 withColorStr:colorHexStr8];

    self.rechargeView.tableView.delegate = self;
    self.rechargeView.tableView.dataSource = self;
    self.rechargeView.inputField.delegate = self;
    [self.rechargeView.rechargeButton addTarget:self action:@selector(rechargeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    WS(weakSelf);
    self.rechargeView.selectMoneyButtonHandle = ^(NSInteger tag) { //选中按钮
        [weakSelf inputTextField:nil type:2];
        weakSelf.rechargeMoney = weakSelf.moneyArray[tag];
        [weakSelf setDetaiLabel:weakSelf.rechargeMoney];
    };
    [self.view addSubview:self.rechargeView];
    
    [self.rechargeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    self.rechargeMoney = self.moneyArray[0]; //默认取第一个
    [self setDetaiLabel:self.rechargeMoney]; //默认显示第一个价格
}

- (void)setDetaiLabel:(NSString *)moneyStr {
    
    if ([moneyStr intValue] > 0) {
        
        int giveMoney = [moneyStr intValue] * 10 * ([self.exchangeRate floatValue] - 1);
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d %@",[moneyStr intValue] * 10,NSLocalizedString(@"COINS_VALUE", nil)] attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr9]}];
        
        if (giveMoney > 0) {
            NSMutableAttributedString *str2 = [[NSMutableAttributedString  alloc] initWithString:[NSString stringWithFormat:@"%@",[Strings giveCoinsWithCount:[NSString stringWithFormat:@"%d",giveMoney]]] attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr4]}];
            [str1 appendAttributedString:str2];
        }
        
        self.rechargeView.exchangeLabel.attributedText = str1;
    } else {
        self.rechargeView.exchangeLabel.text = @"";
    }
    
}

#pragma makr - 转为model
- (void)dicChangeToModel:(NSDictionary *)dic {
    
    TDSelectPayModel *model = [TDSelectPayModel mj_objectWithKeyValues:dic];
    if (model) {
        [self.payArray addObject:model];
    }
}

#pragma mark - 确定充值
- (void)rechargeButtonAction:(UIButton *)sender {
    
    if (self.isHidePurchase) { //0 微信; 1支付宝
        self.payType == 0 ? [self createOrderWithType:1] : [self createOrderWithType:2];
        
    } else { //内购
        [self createOrderWithType:3];
    }
}

#pragma mark - 创建订单
- (void)createOrderWithType:(NSInteger)type {
    
    if (![self.baseTool networkingState]) {
        return;
    }
    
    if ([self.rechargeMoney intValue] == 0) {
        [self.view makeToast:NSLocalizedString(@"ENTER_OR_SELECT_RECHARGE_MONEY", nil) duration:1.08 position:CSToastPositionCenter];
        return;
    }
    
    NSLog(@"充值金额 ----> %@",self.rechargeMoney);
    
    [self.rechargeView.activityView startAnimating];
    self.view.userInteractionEnabled = NO;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.username forKey:@"username"];
    [params setValue:self.rechargeMoney forKey:@"coin_amount"];
    
    if (type == 1) {//微信
        params[@"pay_method"] = @1;
        
    } else if (type == 2) {//支付宝
        params[@"pay_method"] = @2;
        
    } else if (type == 3) {//内购
        params[@"pay_method"] = @5;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/finance/generate_prepaid_order_and_pay/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self.view.userInteractionEnabled = YES;
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            self.orderId = responseObject[@"data"][@"order_id"];
            
            if (type == 1) {
                self.weChatItem = [weChatParamsItem mj_objectWithKeyValues:responseObject[@"data"]];
                [self payByWeChat];
                
            }
            else if (type == 2) {
                self.aliPayModel = [TDAliPayModel mj_objectWithKeyValues:responseDic[@"data"][@"data_url"]];
                [self payByAliPay];
                
            }
            else if (type == 3) {
                self.purchaseManager.purchaseModel.total_fee = self.rechargeMoney;
                self.purchaseManager.purchaseModel.userName = self.username;
                self.purchaseManager.purchaseModel.trader_num = responseObject[@"data"][@"order_id"];
                [self rqPayByApple];
            }
        } else {
            
        }
        
        [self.rechargeView.activityView stopAnimating];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.rechargeView.activityView stopAnimating];
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 微信支付
- (void)payByWeChat {
    
    [[[WeChatPay alloc] init] submitPostWechatPay:self.weChatItem];
}

#pragma mark - 支付宝支付
- (void)payByAliPay {
    
    [[[TDAlipay alloc] init] submitPostAliPay:self.aliPayModel];
}

#pragma mark - 苹果内购
- (void)rqPayByApple {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"IS_RECHARGE", nil)];
    SVProgressHUD.defaultMaskType = SVProgressHUDMaskTypeBlack;
    SVProgressHUD.defaultStyle = SVProgressHUDAnimationTypeNative;
    
    int payType = 1;
    switch ([self.rechargeMoney intValue]) {
        case 98:
            payType = 1;
            break;
        case 198:
            payType = 2;
            break;
        case 298:
            payType = 3;
            break;
        case 488:
            payType = 4;
            break;
        case 798:
            payType = 5;
            break;
        case 998:
            payType = 6;
            break;
        default:
            break;
    }
    self.isPurchassing = YES;
    [self.purchaseManager reqToUpMoneyFromApple:payType];
}

#pragma mark - textField Delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (TDHeight < 500) {
        [self.rechargeView.tableView setContentOffset:CGPointMake(0, 79) animated:YES];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [self.rechargeView setMoneyViewData:self.moneyArray withType:2];
    if ([textField.text intValue] == 0) {
        [self setDetaiLabel:@""];
    }
    [self inputTextField:textField.text type:1];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSMutableString *moneyStr = [[NSMutableString alloc] initWithString:textField.text];
    if (range.length == 0) { //增
        [moneyStr appendString:string];
    } else { //删
        [moneyStr deleteCharactersInRange:NSMakeRange(moneyStr.length - 1, 1)];
    }
    if (moneyStr.length > 5) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"ENTER_LASS_FIVE", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        
        [alert show];
        return NO;
    }
    [self setDetaiLabel:moneyStr];
    NSLog(@" --- %@ ---- %lu ---- %lu ----- %@ === %@",textField.text,(unsigned long)range.location,(unsigned long)range.length,string,moneyStr);
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self.rechargeView.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField.text intValue] == 0) {
        [self inputTextField:nil type:2];
    }
    self.rechargeMoney = textField.text;
    NSLog(@"输入金额 --- %@",textField.text);
}

- (void)inputTextField:(NSString *)title type:(NSInteger)type {
    self.rechargeView.inputField.text = title;
    if (type == 1) {
        self.rechargeView.inputField.backgroundColor = [UIColor colorWithHexString:colorHexStr4];
        self.rechargeView.inputField.textColor =[UIColor whiteColor];
        
    } else {
        self.rechargeView.inputField.backgroundColor = [UIColor whiteColor];
        self.rechargeView.inputField.textColor = [UIColor colorWithHexString:colorHexStr8];
    }
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.isHidePurchase ? self.payArray.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    
    TDSelectPayModel *model = self.payArray[indexPath.row];
    TDSelectPayCell *cell = [[TDSelectPayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDSelectPayCell"];
    cell.payModel = model;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.rechargeView.inputField resignFirstResponder];
    
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
    
    [self.rechargeView.tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *sectionView = [[UIView alloc] init];
    sectionView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestrure)];
    [sectionView addGestureRecognizer:gesture];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    titleLabel.text = self.isHidePurchase ? NSLocalizedString(@"SELECT_PAYWAY", nil) : @"";
    titleLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [sectionView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(sectionView.mas_left).offset(18);
        make.centerY.mas_equalTo(sectionView.mas_centerY);
    }];
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.isHidePurchase ? 28 : 0;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.rechargeView.inputField resignFirstResponder];
}

#pragma mark - 返回
- (void)backButtonAction:(UIButton *)sender {
    if (self.isPurchassing) {
        [self.view makeToast:NSLocalizedString(@"IS_RECHARGE_NO_LEVE", nil) duration:1.08 position:CSToastPositionCenter];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)tapGestrure {
    [self.rechargeView.inputField resignFirstResponder];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end


