//
//  TDVideoUrlPlayController.h
//  edX
//
//  Created by Elite Edu on 17/3/31.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDVideoBarView.h"

@interface TDVideoUrlPlayController : UIViewController

@property (nonatomic,strong) NSString *url;
@property (nonatomic,strong) TDVideoBarView *barView;//底部控制栏
@property (nonatomic,assign) BOOL hideStatusBar;

@property (nonatomic,copy) void(^fullScreenButtonHandle)();//点击全屏按钮处理
- (void)stopVideoAction;//停止播放视频

@end
