//
//  TDBaseViewController.h
//  edX
//
//  Created by Elite Edu on 16/12/5.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXFlowErrorViewController.h"

@interface TDBaseViewController : UIViewController

@property (nonatomic,strong) UILabel *titleViewLabel;
@property (nonatomic,strong) UIButton *leftButton;
@property (nonatomic,strong) UIButton *rightButton;

@property (nonatomic,copy) void(^rightButtonHandle)();
- (void)backButtonAction:(UIButton *)sender;
/* 
 首次进入加载页面
 */
@property (nonatomic,strong) UIView *loadIngView;
- (void)setLoadDataView;

/*
 无数据页面
 */
@property (nonatomic,strong) UIView *nullView;
- (void)setNullDataView:(NSString *)title;

@end
