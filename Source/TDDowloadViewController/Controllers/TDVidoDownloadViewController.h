//
//  TDVidoDownloadViewController.h
//  edX
//
//  Created by Ben on 2017/6/12.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDEditeBottomView.h"

#import "OEXCustomEditingView.h"

@class NetworkManager;
@class OEXInterface;
@class OEXRouter;
@class RouterEnvironment;

@interface TDVidoDownloadViewController : TDBaseViewController

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) TDEditeBottomView *customEditing;

@property (nonatomic,strong) NSMutableArray *arr_CourseData;
@property (nonatomic, strong) OEXInterface *dataInterface;

@property (nonatomic,copy) void(^judgEditeHandle)(BOOL isTableEditing);
@property (nonatomic,copy) void(^hideEditeHandle)(BOOL isHidden);
@property (nonatomic,copy) void(^checkEditeHandle)(BOOL isChecked);
@property (nonatomic,copy) void(^reloadSubDataHandle)();
@property (nonatomic,copy) void(^fullScreenHanle)(BOOL isFullScreen);

@end
