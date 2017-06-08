//
//  TDCouponModel.h
//  edX
//
//  Created by Ben on 2017/6/7.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDCouponModel : NSObject

@property (nonatomic,strong) NSString *remark;//备注
@property (nonatomic,strong) NSString *coupon_type;//满减券
@property (nonatomic,strong) NSString *cutdown_price;//减的money
@property (nonatomic,strong) NSString *coupon_end_at;//结束时间
@property (nonatomic,strong) NSString *coupon_begin_at;//开始时间
@property (nonatomic,strong) NSString *coupon_name;//文本 ："满500减50"
@property (nonatomic,strong) NSString *discount_rate;//打多少折
@property (nonatomic,strong) NSString *id;//用户领取优惠券记录id

@property (nonatomic,strong) NSString *give_coin;//赠送宝典数量
@property (nonatomic,strong) NSString *redeem_code;//兑换码
@property (nonatomic,strong) NSString *coupon_issue_id;
@property (nonatomic,strong) NSString *is_active;//优惠券是否有效
@property (nonatomic,strong) NSString *created_at;//优惠券创建时间
@property (nonatomic,strong) NSString *act_min_price;//最低使用金额才能享受优惠
@property (nonatomic,strong) NSString *issue_count;//发行优惠券数量
@property (nonatomic,strong) NSString *use_coupon_at;//用户使用优惠券时间
@property (nonatomic,strong) NSString *issue_remain_count;//优惠券剩余数量
@property (nonatomic,strong) NSString *created_by_id;//优惠券创建者id

@property (nonatomic,assign) NSInteger type;//1 折扣券，2 满满券，3 企业优惠券
@property (nonatomic,assign) NSInteger count;//优惠券数量
@property (nonatomic,assign) NSInteger pages;//总页数
@property (nonatomic,assign) BOOL isSelected;//是否点击右上角的问号
@property (nonatomic,strong) NSString *status;//
@property (nonatomic,strong) NSString *signStr;//已使用，已过期


/*
 "give_coin": 0,
 "remark": "满400减10元",
 "redeem_code": "lmy004",
 "coupon_issue_id": 32,
 "coupon_type": "满减券",
 "cutdown_price": 10,
 "is_active": true,
 "created_at": "2017-04-14T15:47:00+08:00",
 "act_min_price": 400,
 "issue_count": 100,
 "use_coupon_at": null,
 "coupon_end_at": "2037-04-14T15:46:00+08:00",
 "issue_remain_count": 95,
 "discount_rate": 0,
 "created_by_id": 800000200,
 "coupon_begin_at": "2017-04-14T15:46:00+08:00",
 "id": 104,
 "coupon_name": "满400减10块"
 },
 */

@end
