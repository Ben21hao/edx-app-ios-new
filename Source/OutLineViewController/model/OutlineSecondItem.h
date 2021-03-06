//
//  OutlineSecondItem.h
//  edX
//
//  Created by Elite Edu on 16/10/19.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OutlineSecondItem : NSObject

@property (nonatomic,strong) NSString *active;//有效性false
@property (nonatomic,strong) NSString *display_name;//章，节，单元显示名称
@property (nonatomic,strong) NSString *format;//功课类型（Homework，Lab等）
@property (nonatomic,strong) NSString *url_name;//章，节，单元url
@property (nonatomic,strong) NSArray *units;//课程单元信息
@property (nonatomic,strong) NSString *graded;//是否计分

@end
