//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <NewRelicAgent/NewRelic.h>
#import <SEGAnalytics.h>

#import "OEXAppDelegate.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXFabricConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNewRelicConfig.h"
#import "OEXPushProvider.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXSegmentConfig.h"

#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>

@interface OEXAppDelegate () <UIApplicationDelegate>

@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;
@property (nonatomic, strong) OEXEnvironment* environment;

@end


@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    
    
    [WXApi registerApp:APPID_Weixin]; //1.向微信注册
    
    [self judgeAppVersion];//判断版本是否更新
    
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state.
    // dispatch_async so that the XCTest bundle (where TestEnvironmentBuilder lives) has already loaded
    if([[NSProcessInfo processInfo].arguments containsObject:@"-UNIT_TEST"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class builder = NSClassFromString(@"TestEnvironmentBuilder");
            NSAssert(builder != nil, @"Can't find test environment builder");
            (void)[[builder alloc] init];
        });
        return YES;
    }
    if([[NSProcessInfo processInfo].arguments containsObject:@"-END_TO_END_TEST"]) {
        [[[OEXSession alloc] init] closeAndClearSession];
        [OEXFileUtility nukeUserData];
    }
#endif

    // logout user automatically if server changed
    [[[ServerChangedChecker alloc] init] logoutIfServerChanged];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];

    [self.environment.router openInWindow:self.window];

    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UIViewController *topController = self.window.rootViewController;
    
    return [topController supportedInterfaceOrientations];
}

//2.微信
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    return [WXApi handleOpenURL:url delegate:(id)self];
}

- (void)judgeAppVersion {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = @"https://beta.eliteu.cn/api/mobile/v0.5/get_last_version";
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:@"iOS" forKey:@"platform"];
    
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            
            NSString *serviceStr = responseDic[@"data"][@"last_version"][@"version"];
            
            NSString *loacalStr = [[NSUserDefaults standardUserDefaults] valueForKey:@"APP_Version_Service"]; //存储安装后，第一次提示更新的版本
            
            if ([loacalStr isEqualToString:serviceStr]) { //远程版本没有再次更新，即已提醒过一次
                return;
            }
            [[NSUserDefaults standardUserDefaults] setValue:serviceStr forKey:@"APP_Version_Service"];
            
            NSString *infoFile = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
            NSMutableDictionary *infodic = [[NSMutableDictionary alloc] initWithContentsOfFile:infoFile];
            NSString *appVersionStr = infodic[@"CFBundleShortVersionString"];//app版本号
            
            if ([serviceStr compare:appVersionStr options:NSNumericSearch] == NSOrderedDescending) {//降序 : 后台的版本 > app的版本
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SYSTEM_WARING", nil)
                                                                    message:NSLocalizedString(@"NEW_VERSION_UPDATE", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                alertView.tag = 100;
                [alertView show];
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
    
}


- (void)onResp:(BaseResp *)resp {
    
    if([resp isKindOfClass:[PayResp class]]){
        
        if (resp.errCode == WXSuccess) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"aliPaySuccess" object:nil]];
            
        } else {
            NSString *strMsg = [NSString stringWithFormat:@"errcode:%d", resp.errCode];
            switch (resp.errCode) {
                case WXSuccess:
                    strMsg = NSLocalizedString(@"PAY_SUCCESS", nil);
                    break;
                case WXErrCodeUserCancel:
                    strMsg = NSLocalizedString(@"PAY_CANCEL", nil);
                    break;
                case WXErrCodeSentFail:
                    strMsg = NSLocalizedString(@"PAY_FAIL", nil);
                    break;
                case WXErrCodeAuthDeny:
                    strMsg = NSLocalizedString(@"PAY_AUTHENRIZATE_FAIL", nil);
                    break;
                default:
                    strMsg = NSLocalizedString(@"NO_SUPPORT_WECHAT", nil);
                    break;
            }
            
            NSString *strTitle = NSLocalizedString(@"PAY_RESULT", nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                            message:strMsg
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
            alert.delegate = self;
            [alert show];
        }
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    // NOTE: 9.0以后使用新API接口
    //    NSLog(@"url--%@",url);
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSString *resultStatus = resultDic[@"resultStatus"];
            
            NSString *strTitle = NSLocalizedString(@"PAY_RESULT", nil);
            NSString *str;
            switch ([resultStatus integerValue]) {
                case 6001:
                    str = NSLocalizedString(@"PAY_CANCEL", nil);
                    break;
                case 9000:
                    str = NSLocalizedString(@"PAY_SUCCESS", nil);
                    break;
                case 8000:
                    str = NSLocalizedString(@"IS_HANDLE", nil);
                    break;
                case 4000:
                    str = NSLocalizedString(@"PAY_FAIL", nil);
                    break;
                case 6002:
                    str = NSLocalizedString(@"NETWORK_CONNET_FAIL", nil);
                    break;
                    
                default:
                    break;
            }
            if ([resultStatus isEqualToString:@"9000"]) {
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"aliPaySuccess" object:nil]];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
                                                                message:str
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil, nil];
                alert.delegate = self;
                [alert show];
            }
            
            NSLog(@"B---result = %@",resultDic);
        }];
    }
    //这里判断是否发起的请求为微信支付，如果是的话，用WXApi的方法调起微信客户端的支付页面（://pay 之前的那串字符串就是你的APPID，）
    return  [WXApi handleOpenURL:url delegate:(id<WXApiDelegate>)self];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 100) {
        if (buttonIndex == 1) { //跳转appstore
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/cn/app/%E8%8B%B1%E8%8D%94%E6%95%99%E8%82%B2-%E4%BC%81%E4%B8%9A%E7%AE%A1%E7%90%86%E5%9C%A8%E7%BA%BF%E8%AF%BE%E5%A0%82/id1179609181?mt=8"]];
        }
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"aliPayFail" object:nil];
    }
}


- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = false;
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        if(handled) {
            return handled;
        }
    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
        [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    }
   
    ////微信支付成功时调用，回到第三方应用中
    if ([url.scheme isEqualToString:APPID_Weixin]) {
        return  [WXApi handleOpenURL:url delegate:(id<WXApiDelegate>)self];
    }
    //    如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode
        
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
    }

    
    return handled;
}

/*前后台处理*/
- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"-------> =后台= <---------");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"-------> =前台= <---------");
    
    
    NSString *secondStr = [[NSUserDefaults standardUserDefaults] valueForKey:@"Free_Course_Free_Time"];
    
    if ([secondStr floatValue] > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"App_EnterForeground_Free_Course" object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"App_EnterForeground_Get_Code" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"-------> =注销= <---------");
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.environment.pushNotificationManager didReceiveRemoteNotificationWithUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self.environment.pushNotificationManager didReceiveLocalNotificationWithUserInfo:notification.userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self.environment.pushNotificationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.environment.pushNotificationManager didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)())completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        OEXLogError(@"DOWNLOADS", @"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        OEXLogInfo(@"DOWNLOADS", @"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

#pragma mark Environment

- (void)setupGlobalEnvironment {
    [UserAgentOverrideOperation overrideUserAgent:nil];
    
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];

    OEXConfig* config = self.environment.config;

    //Logging
    [DebugMenuLogger setup];

    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];

    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey]];
    }
    
    //Initialize Firebase
    if (config.isFirebaseEnabled) {
        [FIRApp configure];
        [[FIRAnalyticsConfiguration sharedInstance] setAnalyticsCollectionEnabled:YES];
    }

    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }

    //Initialize Fabric
    OEXFabricConfig* fabric = [config fabricConfig];
    if(fabric.appKey && fabric.isEnabled) {
        [Fabric with:@[CrashlyticsKit]];
    }
    
}

@end
