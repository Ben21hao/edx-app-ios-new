//
//  OEXCourse.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CourseMediaInfo;
@class OEXLatestUpdates;
@class OEXCoursewareAccess;

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, OEXStartType) {
    OEXStartTypeString,
    OEXStartTypeTimestamp,
    OEXStartTypeNone
};

NSString* NSStringForOEXStartType(OEXStartType type);
OEXStartType OEXStartTypeForString(NSString* type);

@interface OEXCourseStartDisplayInfo : NSObject

- (id)initWithDate:(nullable NSDate*)date displayDate:(nullable NSString*)displayDate type:(OEXStartType)type;

@property (readonly, nonatomic, strong, nullable) NSDate* date;
@property (readonly, copy, nonatomic, nullable) NSString* displayDate;
@property (readonly, assign, nonatomic) OEXStartType type;

@property (readonly, nonatomic) NSDictionary<NSString*, id>* jsonFields;

@end

@interface OEXCourse : NSObject

- (id)initWithDictionary:(NSDictionary*)info;

// TODO: Rename these to CamelCase (MK - eh just make this swift)
@property (readonly, nonatomic, strong, nullable) OEXLatestUpdates* latest_updates;
@property (readonly, nonatomic, strong, nullable) NSDate* end;
@property (readonly, nonatomic, strong) OEXCourseStartDisplayInfo* start_display_info;
@property (readonly, nonatomic, copy, nullable) NSString* name;
@property (readonly, nonatomic, copy, nullable) NSString* org;
@property (readonly, nonatomic, copy, nullable) NSString* video_outline;
@property (readonly, nonatomic, copy, nullable) NSString* effort;//学习时长（约60小时）
@property (readonly, nonatomic, copy, nullable) NSString* course_id;
@property (readonly, nonatomic, copy, nullable) NSString* root_block_usage_key;
@property (readonly, nonatomic, copy, nullable) NSString* subscription_id;
@property (readonly, nonatomic, copy, nullable) NSString* number;
@property (readonly, nonatomic, copy, nullable) NSString* overview_html;
@property (readonly, nonatomic, copy, nullable) NSString* short_description;
@property (readonly, nonatomic, copy, nullable) NSString* moreDescription;//更多课程详情
@property (readonly, nonatomic, copy, nullable) NSString* intro_video_3rd_url;//预告url
@property (readonly, nonatomic, copy, nullable) NSNumber* listen_count;//报名人数
@property (readonly, nonatomic, copy, nullable) NSString* professor_username;//教授名字
@property (readonly, nonatomic, copy, nullable) NSNumber *course_price;//价格
@property (readonly, nonatomic, copy, nullable) NSString* course_updates;         //  ANNOUNCEMENTS URL
@property (readonly, nonatomic, copy, nullable) NSString* course_handouts;        //  HANDOUTS URL
@property (readonly, nonatomic, copy, nullable) NSString* course_about;           // COURSE INFO URL
@property (readonly, nonatomic, strong, nullable) OEXCoursewareAccess* courseware_access;
@property (readonly, nonatomic, copy, nullable) NSString* discussionUrl;
@property (readonly, nonatomic, copy, nullable) NSDictionary<NSString*, CourseMediaInfo*>* mediaInfo;
@property (readonly, nonatomic, strong, nullable) CourseMediaInfo* courseImageMediaInfo;
@property (readonly, nonatomic, strong, nullable) CourseMediaInfo* courseVideoMediaInfo;

@property (readonly, nonatomic, assign) BOOL isStartDateOld;
@property (readonly, nonatomic, assign) BOOL isEndDateOld;

@property (readonly, nonatomic, strong, nullable) NSString* courseImageURL;

@property (readonly, nonatomic, copy, nullable) NSNumber *give_coin; //购买课程赠送宝典
@property (readonly, nonatomic, copy, nullable) NSString *begin_at; //购买课程赠送宝典开始时间
@property (readonly, nonatomic, copy, nullable) NSString *end_at; //购买课程赠送宝典结束时间
@property (readonly, nonatomic, copy, nullable) NSNumber *is_eliteu_course;//是否为付费课程

@property (readonly, nonatomic, copy, nullable) NSNumber *course_status; //课程状态 1.未购买未试听 2.试听 3.试听已结束 4.已购买
@property (readonly, nonatomic, copy, nullable) NSString *trial_expire_at; //试听课程失效时间
@property (readonly, nonatomic, copy, nullable) NSNumber *trial_seconds;//剩余试听时间；－2 代表未购买未试听；－1 代表已购买；0 代表试听已结束；其他正整数 试听中
@property (nonatomic,strong) NSString *freeStr;//试听按钮文本

@property (nonatomic,assign) NSInteger submitType; //0 已购买，1 立即加入, 2 查看待支付，3 即将开课

@end


NS_ASSUME_NONNULL_END

