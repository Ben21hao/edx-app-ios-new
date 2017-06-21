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
@property (nonatomic,assign) NSInteger whereFrom;

@property (nonatomic,copy) void(^updateTotalCoinHandle)(NSString *totalStr);

@end
