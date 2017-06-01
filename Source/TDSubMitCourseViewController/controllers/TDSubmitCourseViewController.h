//
//  TDSubmitCourseViewController.h
//  edX
//
//  Created by Ben on 2017/5/2.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDSubmitCourseViewController : TDBaseViewController

@property (nonatomic,strong) NSMutableArray *courseArray;//选择的课程

@property (nonatomic,assign) float totalM; //应该付款金额
@property (nonatomic,copy) NSString *username;
@property (nonatomic,strong) NSString *courseId;
@property (nonatomic,strong) NSString *activity_id;//活动名称
@property (nonatomic,strong) NSString *giftCoin; //赠送宝典数目

@property (nonatomic,assign) BOOL hideShowPurchase;//是否隐藏内购

@end
