//
//  WaitForPayViewController.h
//  edX
//
//  Created by Elite Edu on 16/10/17.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseViewController.h"

@interface WaitForPayViewController : TDBaseViewController

@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *courseId;
@property (nonatomic,assign) NSInteger whereFrom;//1 为结算页

@end
