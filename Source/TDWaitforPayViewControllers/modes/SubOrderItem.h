//
//  SubOrderItem.h
//  edX
//
//  Created by Elite Edu on 16/10/17.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubOrderItem : NSObject

@property(nonatomic,strong)NSString *course_id;//课程ID
@property(nonatomic,strong)NSString *display_name;//课程名字
@property(nonatomic,strong)NSString *image; //图片
@property(nonatomic,strong)NSString *min_price; //最低价格
@property(nonatomic,strong)NSString *price;//价格
@property(nonatomic,strong)NSString *teacher_name;//教授名字

@end
