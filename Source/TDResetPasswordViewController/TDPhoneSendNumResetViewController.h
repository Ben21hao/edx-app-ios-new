//
//  TDPhoneSendNumResetViewController.h
//  edX
//
//  Created by Ben on 2017/5/10.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDPhoneSendNumResetViewController : UIViewController

@property (nonatomic,strong) NSString *phoneStr;
@property (nonatomic,strong) NSString *randomNumber;//本地随机生成的验证码

@end
