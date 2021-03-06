//
//  TDBaseToolModel.m
//  edX
//
//  Created by Elite Edu on 17/1/16.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDBaseToolModel.h"
#import "OEXAppDelegate.h"
#import "edX-Swift.h"
#import "OEXFlowErrorViewController.h"

@implementation TDBaseToolModel

#pragma mark - 是否显示内购
- (void)showPurchase {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"iOS" forKey:@"platform"];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/get_last_version/",ELITEU_URL];
    
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        id code = dict[@"code"];
        if ([code intValue] == 200) {
            NSString *infoFile = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
            NSMutableDictionary *infodic = [[NSMutableDictionary alloc] initWithContentsOfFile:infoFile];
            NSString *appVersion = infodic[@"CFBundleShortVersionString"];//app版本号
            NSString *serviceVersion = dict[@"data"][@"last_version"][@"version"];//后台返回的版本号
            
            BOOL hideShowPurchase = [dict[@"data"][@"last_version"][@"is_audited_passed"] boolValue];//是否已审核通过
            if ([serviceVersion compare:appVersion options:NSNumericSearch] == NSOrderedDescending) {//降序 : 后台的版本 > app的版本
                
                hideShowPurchase = YES;//历史版本都是隐藏内购，使用支付宝和微信
                
                NSLog(@"后台版本 > app版本 --> service:%@ --- app:%@",serviceVersion,appVersion);
                
            } else {
                NSLog(@"app版本 >= 后台版本 --> service:%@ --- app:%@ == %d",serviceVersion,appVersion,hideShowPurchase); //版本相同的时候，就是用后台是否审核通过的返回值
            }
            
            if (self.judHidePurchseHandle) {
                self.judHidePurchseHandle(hideShowPurchase);
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error--%@",error);
    }];
}

#pragma mark - 正则表达式
/*
 手机号码的正则表达式
 */
- (BOOL)isValidateMobile:(NSString *)mobile {
    if (mobile.length <= 0) {
        return NO;
    }
    NSString *phoneRegex = @"^((13[0-9])|(17[0-9])|(14[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";//手机号以13、15、18、14、17开头，八个\d数字字符
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:mobile];
}

/*
 邮箱地址的正则表达式
 */
- (BOOL)isValidateEmail:(NSString *)email {
    if (email.length <= 0) {
        return NO;
    }
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

/*
 身份证的正则表达式
 */
- (BOOL)isValidateIdentify:(NSString *)numberIDCar {
    if (numberIDCar.length <= 0) {
        return NO;
    }
    NSString *regex2 = @"^(\\d{14}|\\d{17})(\\d|[xX])$";
    NSPredicate *identityCardPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex2];
    return [identityCardPredicate evaluateWithObject:numberIDCar];
}

/*
 判断姓名都是中文正则表达式
 */
- (BOOL)isValidateUserName:(NSString *)username {
    if (username.length <= 0) {
        return NO;
    }

    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:username];
}

#pragma mark - 判断登录密码是否正确
- (void)vertifiteLoginPassword:(NSString *)password andName:(NSString *)username onView:(UIView *)view {
    if (![self networkingState]) {
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:username forKey:@"username"];
    [params setValue:password forKey:@"password"];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/check_password/",ELITEU_URL];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *respondDic = (NSDictionary *)responseObject;
        id code = respondDic[@"code"];
        
        if ([code intValue] == 200) {
            if (self.vertifitePasswordHandle) {
                self.vertifitePasswordHandle();
            }
            
        } else if ([code intValue] == 400) {
            [view makeToast:NSLocalizedString(@"PASSWORD_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
        } else {
            NSLog(@"验证登录密码 -- %@",respondDic[@"msg"]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"验证登录密码 -- %ld",(long)error.code);
    }];
}


#pragma mark - 网络监测
- (BOOL)networkingState {
    
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL reachable = [appD.reachability isReachable];
    if (!reachable) {
        [[OEXFlowErrorViewController sharedInstance] showErrorWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessageTrouble]
                                                       onViewController:[UIApplication sharedApplication].keyWindow.rootViewController.view
                                                             shouldHide:YES];
    }
    return reachable;
}

#pragma mark - 小数点后面.00变小
/*
 无颜色设置
 type 1 无划线
 type 2 有划线
 */
- (NSMutableAttributedString *)setString:(NSString *)titleStr withFont:(NSInteger)font type:(NSInteger)type { // type : 1 正常显示； 2 有划线
    if ([titleStr containsString:@"."]) {
        NSRange range = [titleStr rangeOfString:@"."];
        NSString *frontStr = [titleStr substringToIndex:range.location + 1];
        NSString *behindStr = [titleStr substringFromIndex:range.location + 1];
//        NSLog(@"小数点前面 --> %@ == 后面 ----> %@",frontStr,behindStr);
        
        NSInteger smallFont = font * 0.8;
        if (type == 1) {
            NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:frontStr
                                                                                     attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:font] }];
            NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:behindStr
                                                                                     attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:smallFont] }];
            [str1 appendAttributedString:str2];
            return str1;
        } else {
            NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:frontStr
                                                                                     attributes:@{
                                                                                                  NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:font],
                                                                                                  NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)
                                                                                                  }];
            NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:behindStr
                                                                                     attributes:@{
                                                                                                  NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:smallFont],
                                                                                                  NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle)
                                                                                                  }];
            
            [str1 appendAttributedString:str2];
            return str1;
        }
    } else { //无小数点
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:titleStr
                                                                                 attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:font] }];
        return str1;
    }
}
/* 
 有颜色设置
 无划线
 */
- (NSMutableAttributedString *)setDetailString:(NSString *)titleStr withFont:(NSInteger)font withColorStr:(NSString *)colorStr {
    if ([titleStr containsString:@"."]) {
        NSRange range = [titleStr rangeOfString:@"."];
        NSString *behindStr = [titleStr substringWithRange:NSMakeRange(range.location + 1, 2)];//小数点后面两位
        
        NSInteger smallFont = font * 0.8;
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:titleStr
                                                                                 attributes:@{
                                                                                              NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:font],
                                                                                              NSForegroundColorAttributeName : [UIColor colorWithHexString:colorStr]
                                                                                              }];
        NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:behindStr
                                                                                 attributes:@{
                                                                                              NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:smallFont],
                                                                                              NSForegroundColorAttributeName : [UIColor colorWithHexString:colorStr]
                                                                                              }];
        [str1 replaceCharactersInRange:NSMakeRange(range.location + 1, 2) withAttributedString:str2];//替换
        return str1;
        
    } else {//无小数点
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:titleStr
                                                                                 attributes:@{
                                                                                              NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:font],
                                                                                              NSForegroundColorAttributeName : [UIColor colorWithHexString:colorStr]
                                                                                              }];
        return str1;
    }
}

#pragma mark - 昵称保留一下关键词不能使用
- (void)checkNickname:(NSString *)nickname view:(UIView *)view {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:nickname forKey:@"nick_name"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/users/is_keyword/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            if (self.checkNickNameHandle) {
                self.checkNickNameHandle(YES);
            }
        } else {
            
             [view makeToast:NSLocalizedString(@"CONNOT_USE_NICKNAME", nil) duration:1.08 position:CSToastPositionCenter];
            if (self.checkNickNameHandle) {
                self.checkNickNameHandle(NO);
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%ld",(long)error.code);
    }];
}

#pragma mark - 星号隐藏
/*
 电话号码中间星号隐藏
 */
- (NSString *)setPhoneStyle:(NSString *)phoneStr {
    
    if (phoneStr.length > 4) {
        NSMutableString *mStr = [NSMutableString stringWithString:phoneStr];
        NSString *newStr = [mStr stringByReplacingCharactersInRange:NSMakeRange(3, 4) withString:@"****"];
        return newStr;
        
    } else {
        return phoneStr;
    }
    
}
/*
 邮箱中间星号隐藏
 */
- (NSString *)setEmailStyle:(NSString *)emailStr {
    NSRange range = [emailStr rangeOfString:@"@"];
    NSMutableString *mStr = [NSMutableString stringWithString:emailStr];
    
    if (range.location >= 3 && range.location < 100) {
        NSString *newStr = [mStr stringByReplacingCharactersInRange:NSMakeRange(1, range.location - 2) withString:@"****"];
        return newStr;
        
    } else if (range.location == 1 || range.location ==2) {
        [mStr insertString:@"****" atIndex:1];
        return mStr;
        
    } else {
        return emailStr;
    }
}

#pragma mark - 判断时间是否到活动的时间
- (BOOL)judgeDateOverDue:(NSString *)dateStr {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-mm-dd";
    NSDate *date = [formatter dateFromString:dateStr];
    NSDate *now = [NSDate date];
    NSComparisonResult result = [date compare:now];
    switch (result) {
        case NSOrderedAscending: //升序
            return YES;
            break;
        case NSOrderedDescending: //降序
            return NO;
            break;
        case NSOrderedSame: //一样
            return NO;
            break;
        default:
            break;
    }
}

#pragma mark - 截取时间前面的10位 2013-11-17T11:59:22+08:00
- (NSString *)interceptStr:(NSString *)dateStr {
    if (dateStr.length <= 10) {
        return dateStr;
    }
    NSMutableString *str = [[NSMutableString alloc] initWithString:dateStr];
    return [str substringToIndex:10];
}

#pragma mark - 获取字符串size
- (CGSize)getSringSize:(NSString *)str withFont:(NSInteger)font {
    
    CGSize size = [str boundingRectWithSize:CGSizeMake(TDWidth, TDHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:font]} context:nil].size;
    return size;
}

#pragma mark - 返回虚线image的方法
- (UIImage *)drawLineByImageView:(UIImageView *)imageView withColor:(NSString *)colorStr {
    UIGraphicsBeginImageContext(imageView.frame.size); //开始画线 划线的frame
    [imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);//设置线条终点形状
    
    CGFloat lengths[] = {5,1};// 5是每个虚线的长度 1是高度
    CGContextRef line = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(line, [UIColor colorWithHexString:colorStr].CGColor);// 设置颜色
    CGContextSetLineDash(line, 0, lengths, 2); //画虚线
    CGContextMoveToPoint(line, 0.0, 2.0); //开始画线
    CGContextAddLineToPoint(line, 450, 2.0);
    CGContextStrokePath(line);
    
    return UIGraphicsGetImageFromCurrentImageContext();// UIGraphicsGetImageFromCurrentImageContext()返回的就是image
}

#pragma mark - 时间格式 2017-02-24T11:34:50+08:00 --->>> 2017-03-07 09:48:03
- (NSString *)dateFormatStart:(NSString *)dateStr {
    NSString *str = [dateStr stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    NSString *str1 = [str substringToIndex:19];
    NSString *timeStr = [NSString stringWithFormat:@"%@~%@",str,str1];
    NSLog(@"=======> %@ -== %@ -- %@",str,str1,timeStr);
    
    return timeStr;
}


@end


