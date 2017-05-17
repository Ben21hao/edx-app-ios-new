//
//  WeChatPay.m
//  edX
//
//  Created by Elite Edu on 16/11/25.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "WeChatPay.h"
#import "WXApi.h"
#import "Encryption.h"//md5加密


@implementation WeChatPay

- (void)submitPostWechatPay:(weChatParamsItem *)weChatItem {
    //获取到实际调起微信支付的参数后，在app端调起支付
    NSMutableDictionary *dict = [self getPayParam:weChatItem];
    NSMutableString *stamp  = [dict objectForKey:@"timestamp"];
    
    //调起微信支付
    PayReq* req             = [PayReq alloc];
    req.openID              = [dict objectForKey:@"appid"];
    req.partnerId           = [dict objectForKey:@"partnerid"];
    req.prepayId            = weChatItem.prepay_id;
    req.nonceStr            = [dict objectForKey:@"noncestr"];;
    req.timeStamp           = stamp.intValue;
    req.package             = [dict objectForKey:@"package"];
    req.sign                = [dict objectForKey:@"sign"];
    
    [WXApi sendReq:req];
}


- ( NSMutableDictionary *)getPayParam:(weChatParamsItem *)weChatItem {
    
    srand( (unsigned)time(0) );
    
    NSString    *package, *time_stamp, *nonce_str;
    //设置支付参数
    time_t now;
    time(&now);
    time_stamp  = [NSString stringWithFormat:@"%ld", now];
    nonce_str	= [Encryption newMd5:time_stamp];
    
    package         = @"Sign=WXPay";
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    [signParams setObject: weChatItem.appid forKey:@"appid"];
    [signParams setObject: nonce_str forKey:@"noncestr"];
    [signParams setObject: package forKey:@"package"];
    [signParams setObject: weChatItem.mch_id forKey:@"partnerid"];
    [signParams setObject: time_stamp forKey:@"timestamp"];
    [signParams setObject: weChatItem.prepay_id forKey:@"prepayid"];
    //生成签名
    NSString *sign  = [self createMd5Sign:signParams];
    
    //添加签名
    [signParams setObject:sign forKey:@"sign"];
    
    //返回参数列表
    return signParams;
    
}

//创建package签名
-(NSString*) createMd5Sign:(NSMutableDictionary*)dict {
    
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [dict allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        if (   ![[dict objectForKey:categoryId] isEqualToString:@""]
            && ![categoryId isEqualToString:@"sign"]
            && ![categoryId isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [dict objectForKey:categoryId]];
        }
        
    }
    //添加key字段
    [contentString appendFormat:@"key=%@", WEIXIN_PARTNER_ID];
    //得到MD5 sign签名
    NSString *md5Sign = [Encryption newMd5:contentString];
    
    return md5Sign;
}

@end
