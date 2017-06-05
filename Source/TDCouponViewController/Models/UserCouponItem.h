//
//  UserCouponItem.h
//  edX
//
//  Created by Elite Edu on 16/8/29.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UserCouponTextItem;
@interface UserCouponItem : NSObject

@property (nonatomic,copy) NSString *coupon_type;//满减券
@property (nonatomic,copy) NSString *coupon_name;//文本 ："满500减50"
@property (nonatomic,copy) NSString *coupon_begin_at;//开始时间
@property (nonatomic,copy) NSString *coupon_end_at;//结束时间
@property (nonatomic,copy) NSString *cutdown_price;//减的money
@property (nonatomic,copy) NSString *discount_rate;//打多少折
@property (nonatomic,assign) NSInteger pagesize;//总页数
//@property (nonatomic,assign) NSInteger pages;//当前页数
@property (nonatomic,assign) NSInteger status;//
@property (nonatomic,strong) NSString *remark;//备注
@property (nonatomic,assign) BOOL isSelected;//是否点击右上角的问号
@property (nonatomic,assign) NSInteger type;//1 折扣券，2 满满券，3 企业优惠券

@end
