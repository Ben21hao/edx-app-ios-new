//
//  TDRequestBaseModel.h
//  edX
//
//  Created by Elite Edu on 17/3/22.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXAnnouncement.h"
#import "OEXCourse.h"

@interface TDRequestBaseModel : NSObject

//请求失败
@property (nonatomic,copy) void(^requestFailed)();
@property (nonatomic,copy) void(^requestErrorHandle)(NSError *error);

/*
 获取验证码接口：
 msgStr : 验证短信
 phoneStr : 电话号码
 */
- (void)sendVerificationMsg:(NSString *)msgStr phoneStr:(NSString *)phoneStr;
@property (nonatomic,copy) void(^sendMsgHandle)(NSInteger type); //type : 0 成功，1 手机号码已被注册，2 获取验证码失败


/*
 获取课程资料html
 courseID 课程id
 overrideURL 课程资料url
 */
- (void)getCourseHandout:(NSString *)courseID withHandoutUrl:(NSString *)overrideURL;
@property (nonatomic,copy) void(^getCourseHandoutHandle)(NSString *htmlStr);

/*
 获取课程公告
 courseID 课程id
 overrideURL 课程大纲url
*/
- (void)getCourseAnnouncement:(NSString *)courseID;
@property (nonatomic,copy) void(^getCourseAnounceHandl)(NSArray *anounceArray);

/* 
 课程详情
 */
- (void)getCourseDetail:(NSString *)courseID;
@property (nonatomic,copy) void(^courseDetailHandle)(OEXCourse *courseModel);

/*
 判断是否为待支付课程
 */
- (void)judgeCurseIsWaitforPay:(NSString *)username courseId:(NSString *)courseId;
@property (nonatomic,copy) void(^waitforPayCourseHandle)(NSInteger isWaitPayCourse);


/*
 加入指定课程到试听课
 */
- (void)getMyFreeCourseDetail:(NSString *)username courseID:(NSString *)courseID onViewController:(UIViewController *)vc;
@property (nonatomic,copy) void(^addFreeCourseHandle)(NSArray *enrollArray);
@property (nonatomic,copy) void(^showMsgHandle)(NSString *msgType);
@property (nonatomic,copy) void(^addFreeCourseFailed)();

- (void)getMyFreeCourseDetail:(NSString *)username courseID:(NSString *)courseID;//重新获取试听课程信息
@property (nonatomic,copy) void(^getDetailHandle)();

@end
