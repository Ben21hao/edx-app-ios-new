//
//  TDAlertView.h
//  edX
//
//  Created by Elite Edu on 17/1/19.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDAlertView : UIView

@property (nonatomic,copy) void(^cancelHandle)();
@property (nonatomic,copy) void(^sureHandle)(NSString *password);

@property (nonatomic,assign) BOOL vertifiFailed;

@property (nonatomic,strong) UILabel *errorLabel;

@end
