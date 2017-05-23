//
//  TDBaseToolModel.h
//  edX
//
//  Created by Elite Edu on 17/1/16.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDBaseToolModel : NSObject

/*
 内购
 */
@property (nonatomic,copy) void(^judHidePurchseHandle)(BOOL isHidePurchase);
- (void)showPurchase;

/*
 判断手机是否正确
 */
- (BOOL)isValidateMobile:(NSString *)mobile;

/*
 判断邮箱是否正确
 */
- (BOOL)isValidateEmail:(NSString *)email;

/*
 判断身份证是否正确
 */
- (BOOL)isValidateIdentify:(NSString *)numberIDCar;

/*
 判断姓名是否为中文
 */
- (BOOL)isValidateUserName:(NSString *)username;

/*
 验证登录密码是否正确
 */
@property (nonatomic,copy) void(^vertifitePasswordHandle)();
- (void)vertifiteLoginPassword:(NSString *)password andName:(NSString *)username onView:(UIView *)view;

/*
 网络监测 Yes 有网络, No 网络连接出错
 */
- (BOOL)networkingState;

/*
 数字小数点后面显示小一点
 */
- (NSMutableAttributedString *)setString:(NSString *)titleStr withFont:(NSInteger)font type:(NSInteger)type;

/*
 数字颜色与大小
 */
- (NSMutableAttributedString *)setDetailString:(NSString *)titleStr withFont:(NSInteger)font withColorStr:(NSString *)colorStr;
/*
 一个小数点以上
 */
- (NSMutableAttributedString *)setSeveralDetailString:(NSString *)titleStr withFont:(NSInteger)font;


/*
 昵称保留一下关键词不能使用
 */
@property (nonatomic,copy) void(^checkNickNameHandle)(BOOL isSuccess);
- (void)checkNickname:(NSString *)nickname view:(UIView *)view;

/*
 电话号码中间星号隐藏
 */
- (NSString *)setPhoneStyle:(NSString *)phoneStr;
/*
 邮箱中间星号隐藏
 */
- (NSString *)setEmailStyle:(NSString *)emailStr;

/*
 判断活动时间是否过期 Yes 过期，No 未过期
 */
- (BOOL)judgeDateOverDue:(NSString *)dateStr;

/*
 截取时间前面10位
 */
- (NSString *)interceptStr:(NSString *)dateStr;

/*
 时间转换2013-11-17T11:59:22+08:00 ->> 2013-11-17 11:59:22
 */
- (NSString *)changeStypeForTime:(NSString *)timeStr;

/*
 时间间隔
 */
- (NSTimeInterval)intervalForTimeStr:(NSString *)timeStr;

/*
 计算东八区的时间
 */
- (NSDate *)getChinaTime:(NSDate *)date;

/*
 将世界时间串换成东八区时间串
 */
- (NSString *)changeToEight:(NSString *)timeStr;

//当前时间加上秒数
- (NSString *)addSecondsForNow:(NSNumber *)second;

/*
 计算试听剩余时间
 */
- (int)getFreeCourseSecond;

/*
 获取字符串size
 */
- (CGSize)getSringSize:(NSString *)str withFont:(NSInteger)font;

/*
 屏幕横竖屏
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation;

/*
 返回虚线image的方法
 */
- (UIImage *)drawLineByImageView:(UIImageView *)imageView withColor:(NSString *)colorStr;

/*
 时间格式:
 2017-02-24T11:34:50+08:00 --->>> 2017-03-07 09:48:03
 */
- (NSString *)dateFormatStart:(NSString *)dateStr;

@end



