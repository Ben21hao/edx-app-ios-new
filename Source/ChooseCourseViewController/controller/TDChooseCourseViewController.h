//
//  TDChooseCourseViewController.h
//  edX
//
//  Created by Elite Edu on 16/12/10.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBaseViewController.h"

typedef NS_ENUM(NSInteger,TDChooseCourseFrom) {
    TDChooseCourseFromBuy,
    TDChooseCourseFromFree
};

@interface TDChooseCourseViewController : TDBaseViewController

@property (nonatomic,copy) NSString *username;
@property (nonatomic,strong) NSString *courseID;//课程ID
@property (nonatomic,assign) NSInteger whereFrom;//0 立即加入，1 从试听课程弹框；

@end
