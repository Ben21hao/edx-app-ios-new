//
//  TDAlipay.m
//  edX
//
//  Created by Elite Edu on 17/1/14.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDAlipay.h"
#import <AlipaySDK/AlipaySDK.h>
#import "Order.h"

@interface TDAlipay () <UIAlertViewDelegate>

@end

@implementation TDAlipay

- (void)submitPostAliPay:(TDAliPayModel *)aliPayModel {
    
    Order *order = [[Order alloc] init];
    order.partner = aliPayModel.partner;//合作者身份ID
    order.sellerID = aliPayModel.seller_id;//卖家支付宝ID
    order.outTradeNO = aliPayModel.out_trade_no; //订单ID（由商家自行制定）
    order.subject = aliPayModel.subject; //商品名称
    order.body = aliPayModel.body; //商品详情
    order.totalFee = aliPayModel.total_fee;//总金额
    order.notifyURL =  aliPayModel.notify_url; //回调URL - 服务器异步通知页面路径
    order.service = aliPayModel.service;  //接口名称
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    //    order.itBPay = @"30m";
    //    order.showURL = @"m.alipay.com";
    
    
    //    NSString *appScheme = @"alisdkdemo";
    NSString *appScheme = @"org.eliteu.mobile"; //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *orderSpec = [order description]; //将商品信息拼接成字符串
    
    /* 获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode */
    //    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    //    NSString *signedString = [signer signString:orderSpec];
    
    /* 将签名成功字符串格式化为订单字符串,请严格按照该格式 */
    NSString *base64String = aliPayModel.sign;
    NSString *signedString = [self urlEncodedString:base64String];
    NSString *orderString = nil;
    if (signedString != nil) {
        
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"A--reslut = %@",resultDic); //【callback处理支付结果】
            
            NSString *resultStatus = resultDic[@"resultStatus"];
            
            NSString *strTitle = NSLocalizedString(@"PAY_RESULT", nil);
            NSString *str;
            switch ([resultStatus integerValue]) {
                case 6001:
                    str = NSLocalizedString(@"PAY_CANCEL", nil);
                    break;
                case 9000:
                    str = NSLocalizedString(@"PAY_SUCCESS", nil);
                    break;
                case 8000:
                    str = NSLocalizedString(@"IS_HANDLE", nil);
                    break;
                case 4000:
                    str = NSLocalizedString(@"PAY_FAIL", nil);
                    break;
                case 6002:
                    str = NSLocalizedString(@"NETWORK_CONNET_FAIL", nil);
                    break;
                    
                default:
                    break;
            }
            if ([resultStatus isEqualToString:@"9000"]) {
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"aliPaySuccess" object:nil]];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:str delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                alert.delegate = self;
                [alert show];
            }
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"aliPayFail" object:nil];
}

#pragma mark - 加密
- (NSString*)urlEncodedString:(NSString *)string {
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}

@end
