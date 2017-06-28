//
//  TDCourseOutLineModel.h
//  edX
//
//  Created by Ben on 2017/6/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>


/* 节 */
@interface TDOutLineUnitsModel : NSObject

@property(nonatomic,strong)NSString *url_name;//章，节，单元url
@property(nonatomic,strong)NSString *display_name;//章，节，单元显示名称

@end

/* 章 */
@interface TDOutLineSectionsModel : NSObject

@property (nonatomic,strong) NSString *active;//有效性false
@property (nonatomic,strong) NSString *display_name;//章，节，单元显示名称
@property (nonatomic,strong) NSString *format;//功课类型（Homework，Lab等）
@property (nonatomic,strong) NSString *url_name;//章，节，单元url
@property (nonatomic,strong) NSString *graded;//是否计分
@property (nonatomic,strong) NSArray<TDOutLineUnitsModel *> *units;//课程单元信息

@end

/* 总体 */
@interface TDCourseOutLineModel : NSObject

@property (nonatomic,assign) BOOL isOpen;
@property (nonatomic,strong) NSString *active;//有效性false
@property (nonatomic,strong) NSString *display_name;//章，节，单元显示名称
@property (nonatomic,strong) NSString *url_name;//章，节，单元url
@property (nonatomic,strong) NSArray<TDOutLineSectionsModel *> *sections;//课程节信息

@end






