//
//  TDDownloadViewController.h
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

@interface TDDownloadViewController : UIViewController

@property (strong, nonatomic) RouterEnvironment *environment;

@end
