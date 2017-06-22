//
//  TDRechargeSuccessViewController.h
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDRechargeSuccessViewController : TDBaseViewController

@property (nonatomic,strong) NSString *orderId;
@property (nonatomic,assign) NSInteger whereFrom;//0 个人中心， 1 课程结算，2 预约助教

@property (nonatomic,copy) void(^updateTotalCoinHandle)(NSString *totalStr);

@end
