//
//  TDRequestBaseModel.m
//  edX
//
//  Created by Elite Edu on 17/3/22.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDRequestBaseModel.h"
#import "edX-Swift.h"
#import "NSObject+OEXReplaceNull.h"
#import "OEXAuthentication.h"

@interface TDRequestBaseModel ()

@property (nonatomic,assign) BOOL isReqeustAgain;
@property (nonatomic,strong) NSString *acountStr;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *courseId;

@end

@implementation TDRequestBaseModel

#pragma mark - 身份验证-有些接口需要身份验证才能访问
- (AFHTTPSessionManager *)getUserIdentify {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", nil];// 可接受的文本参数规格
    manager.responseSerializer = [AFJSONResponseSerializer serializer]; // 返回的格式 JSON
    manager.requestSerializer = [AFJSONRequestSerializer serializer]; //先讲请求设置为json
    [manager.requestSerializer setValue:@"application/merge-patch+json" forHTTPHeaderField:@"Content-Type"];// 开始设置请求头
    
    /*用户token信息： session.token.tokenType, session.token.accessToken*/
    NSString* authValue = [NSString stringWithFormat:@"%@", [OEXAuthentication authHeaderForApiAccess]];
    [manager.requestSerializer setValue:authValue forHTTPHeaderField:@"Authorization"];//安全验证
    
    return manager;
}

#pragma mark -- 获取验证码
- (void)sendVerificationMsg:(NSString *)msgStr phoneStr:(NSString *)phoneStr {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:phoneStr forKey:@"mobile"];
    [params setValue:msgStr forKey:@"msg"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/send_captcha_message_for_register/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *dict = (NSDictionary *)responseObject;
        id code = dict[@"code"];
        
        NSInteger type = 0;
        if ([code intValue] == 200) {
            type = 0;
            
        } else if([code intValue] == 403){//手机已被注册
            type = 1;
            
        } else {
            type = 2;
        }
        if (self.sendMsgHandle) {
            self.sendMsgHandle(type);
        }
        NSLog(@"获取验证码 -- %@",dict[@"msg"]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.sendMsgHandle) {
            self.sendMsgHandle(2);
        }
        NSLog(@"获取验证码失败 %ld",(long)error.code);
    }];
}


#pragma mark - 课程资料
- (void)getCourseHandout:(NSString *)courseID withHandoutUrl:(NSString *)overrideURL {

    AFHTTPSessionManager *manager = [self getUserIdentify];//身份验证
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/course_info/%@/handouts",ELITEU_URL,courseID];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       
        NSDictionary *responseDic = (NSDictionary *)responseObject;
    
        NSString *htmlStr = responseDic[@"handouts_html"];
        if ([htmlStr isEqual:[NSNull null]]) {
            htmlStr = @"";
        }
        if (self.getCourseHandoutHandle) {
            self.getCourseHandoutHandle(htmlStr);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取试听课程大纲失败 %ld",(long)error.code);
    }];
}

#pragma mark - 获取课程公告
- (void)getCourseAnnouncement:(NSString *)courseID {
    
    AFHTTPSessionManager *manager = [self getUserIdentify];//身份验证
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/course_info/%@/updates",ELITEU_URL,courseID];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSArray *responseArray = (NSArray *)responseObject;
        if (responseArray.count > 0) {
            NSDictionary *responseDic = responseArray[0];
            OEXAnnouncement *anounceModel = [[OEXAnnouncement alloc] initWithDictionary:responseDic];
            
            NSString *htmlStr = responseDic[@"content"];
            if ([htmlStr isEqual:[NSNull null]]) {
                htmlStr = @"";
                anounceModel.content = htmlStr;
            }
            if (self.getCourseAnounceHandl && anounceModel) {
                self.getCourseAnounceHandl(anounceModel);
            }
            
        } else {
            if (self.requestFailed) {
                self.requestFailed();
            }
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取试听课公告失败 %ld",(long)error.code);
    }];
}

#pragma mark - 获取课程详情
- (void)getCourseDetail:(NSString *)courseID {
    
    AFHTTPSessionManager *manager = [self getUserIdentify];//身份验证
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/courses/%@",ELITEU_URL,courseID];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        OEXCourse *courseModel = [[OEXCourse alloc] initWithDictionary:responseDic];
        
        TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
        NSString *triaStr = [baseTool addSecondsForNow:courseModel.trial_seconds];
        [[NSUserDefaults standardUserDefaults] setValue:triaStr forKey:@"Free_Course_Date_Str"];
        
        if (self.courseDetailHandle && courseModel) {
            self.courseDetailHandle(courseModel);
        }
        NSLog(@"获取试听课程详情 -- %@ -->> %@",responseDic,courseModel.trial_expire_at);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.requestErrorHandle) {
            self.requestErrorHandle(error);
        }
        NSLog(@"获取试听课程详情失败 %ld",(long)error.code);
    }];
}

#pragma mark - 	加入指定课程到试听课
- (void)getMyFreeCourseDetail:(NSString *)username courseID:(NSString *)courseID onViewController:(UIViewController *)vc {
    
    self.username = username;
    self.courseId = courseID;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:username forKey:@"username"];
    [params setValue:courseID forKey:@"course_id"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/add_course_to_listening_courses/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        int code = [responseDic[@"code"] intValue];
        
        if (code == 200) {
            NSDictionary *enrollDic = responseDic[@"data"][@"enroll"];
            NSDictionary *dict = [enrollDic oex_replaceNullsWithEmptyStrings];
            UserCourseEnrollment *enrollment = [[UserCourseEnrollment alloc] initWithDictionary:dict];
            
            NSMutableArray *array = [[NSMutableArray alloc] init];
            [array addObject:enrollment];
            
            if (self.addFreeCourseHandle) {
                self.addFreeCourseHandle(array);
            }
            
            TDBaseToolModel *toolModel = [[TDBaseToolModel alloc] init];
            NSString *timeStr = [toolModel addSecondsForNow:[NSNumber numberWithInteger:enrollment.trial_seconds]];
            [[NSUserDefaults standardUserDefaults] setValue:timeStr forKey:@"Free_Course_Date_Str"];
            
            [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%ld",(long)enrollment.trial_seconds] forKey:@"Free_Course_Free_Time"];
            [[NSUserDefaults standardUserDefaults] setValue:courseID forKey:@"Free_Course_CourseID"];
            [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"Free_Course_Has_Add"];
            
            NSLog(@"加入试听课程的结果 ---  %ld -->> %@ - 目录 %@",(long)enrollment.trial_seconds,enrollment.trial_expire_at,enrollment.course.video_outline);
            
        } else {
            
            NSString *msg = NSLocalizedString(@"FAILED_GET_FREE", nil);
            if (code == 301) {//已经购买课程无需试听
                msg = NSLocalizedString(@"HAD_BUY", nil);
            } else if (code == 302) {//试听已结束
                msg = NSLocalizedString(@"FREE_COURSE_ENDED", nil);
            }
            if (self.showMsgHandle) {
                self.showMsgHandle(msg);
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (self.isReqeustAgain == YES) {//弹框，提示重新登陆，然后跳转到登陆界面
            if (self.addFreeCourseFailed) {
                self.addFreeCourseFailed();
            }
        } else {
            self.isReqeustAgain = YES;
            [self beginLoginActionViewController:vc];
        }
        
//        NSString *str = [[NSString alloc] initWithData:error.userInfo[@"com.alamofire.serialization.response.error.data"] encoding:NSUTF8StringEncoding];
//        NSLog(@"获取试听课程详情失败 %ld--->>> %@",(long)error.code,str);
    }];
    
}

#pragma mark - 登录相关操作
- (void)beginLoginActionViewController:(UIViewController *)vc {
    
    self.acountStr = [[NSUserDefaults standardUserDefaults] valueForKey:@"User_Login_Name"];
    self.password = [[NSUserDefaults standardUserDefaults] valueForKey:@"User_Login_Password"];
    
    if (self.acountStr.length > 0 && self.password.length > 0) {
        [OEXAuthentication requestTokenWithUser:self.acountStr password:self.password completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            [self handleLoginResponseWith:data response:response error:error onViewController:vc];
        }];
    } else {//缺失账号或者密码
        if (self.addFreeCourseFailed) {
            self.addFreeCourseFailed();
        }
    }
}

- (void)handleLoginResponseWith:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error onViewController:(UIViewController *)vc {
    
    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        
        if(httpResp.statusCode == 200) {//登录成功,再次加入课程
            [self getMyFreeCourseDetail:self.username courseID:self.courseId onViewController:vc];
            
        } else {
            if (self.addFreeCourseFailed) {
                self.addFreeCourseFailed();
            }
        }
    } else {
        if (self.addFreeCourseFailed) {
            self.addFreeCourseFailed();
        }
    }
}


@end

