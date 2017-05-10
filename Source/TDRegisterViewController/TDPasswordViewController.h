//
//  TDPasswordViewController.h
//  edX
//
//  Created by Elite Edu on 17/1/3.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,TDSetPasswordFrom) {
    TDSetPasswordFromPhone,
    TDSetPasswordFromEmai
};


@interface TDPasswordViewController : TDBaseViewController

@property (nonatomic,assign) NSInteger whereFrom;
@property (nonatomic,strong) NSString *acountStr;

@end
