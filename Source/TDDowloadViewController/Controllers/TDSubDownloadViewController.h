//
//  TDSubDownloadViewController.h
//  edX
//
//  Created by Ben on 2017/6/12.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NetworkManager;
@class OEXInterface;
@class OEXRouter;
@class RouterEnvironment;

@interface TDSubDownloadViewController : TDBaseViewController

@property (strong, nonatomic) RouterEnvironment *environment;

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *arr_CourseData;

@end
