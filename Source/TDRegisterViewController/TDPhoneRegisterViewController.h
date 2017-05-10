//
//  TDPhoneRegisterViewController.h
//  edX
//
//  Created by Elite Edu on 16/12/30.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDPhoneRegisterViewController : TDBaseViewController

@property (nonatomic,strong) NSString *phoneStr;
@property (nonatomic,strong) NSString *randomNumber;//本地随机生成的验证码

@end
