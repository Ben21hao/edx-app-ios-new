//
//  TDRechargeViewController.h
//  edX
//
//  Created by Elite Edu on 16/12/4.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDRechargeViewController : TDBaseViewController

@property (nonatomic,assign) NSInteger whereFrom; //0 个人中心，1 其他
@property (nonatomic,assign) double currentCanons; //当前宝典数量
@property (nonatomic,copy) NSString *username; //用户名
@property (nonatomic,copy) void(^rechargeSuccessHandle)();

@end
