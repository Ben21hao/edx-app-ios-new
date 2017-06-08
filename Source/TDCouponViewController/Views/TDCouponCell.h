//
//  TDCouponCell.h
//  edX
//
//  Created by Ben on 2017/6/6.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDCouponModel.h"

@interface TDCouponCell : UITableViewCell

@property (nonatomic,strong) TDCouponModel *couponModel;
@property (nonatomic,copy) void(^showDetailHandle)(BOOL isSelected);

@end
