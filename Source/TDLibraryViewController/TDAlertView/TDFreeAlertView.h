//
//  TDFreeAlertView.h
//  edX
//
//  Created by Elite Edu on 17/3/15.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDFreeAlertView : UIView

- (instancetype)initWitType:(NSInteger)type;//0 加入试听课程；1 试听结束

@property (nonatomic,copy) void(^cancelButtonHandle)();
@property (nonatomic,copy) void(^sureButtonHandle)();

@end
