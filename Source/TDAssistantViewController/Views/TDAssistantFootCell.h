//
//  TDAssistantFootCell.h
//  edX
//
//  Created by Elite Edu on 17/2/13.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDAssistantServiceModel.h"

@interface TDAssistantFootCell : UITableViewCell

@property (nonatomic,assign) NSInteger whereFrom;
@property (nonatomic,assign) BOOL isComment;
@property (nonatomic,assign) int score;
@property (nonatomic,strong) NSString *startTime;

@property (nonatomic,strong) TDAssistantServiceModel *model;

@property (nonatomic,copy) void(^endterButtonHandle)();
@property (nonatomic,copy) void(^cancelButtonHandle)();
@property (nonatomic,copy) void(^commentButtonHandle)();

@end
