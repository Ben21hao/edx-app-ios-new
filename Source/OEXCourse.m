//
//  OEXCourse.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourse.h"

#import "edX-Swift.h"

#import "NSDate+OEXComparisons.h"
#import "NSObject+OEXReplaceNull.h"
#import "NSMutableDictionary+OEXSafeAccess.h"
#import "OEXDateFormatting.h"
#import "OEXLatestUpdates.h"
#import "OEXCoursewareAccess.h"

OEXStartType OEXStartTypeForString(NSString* type) {
    NSDictionary* startTypes = @{
                                 @"string" : @(OEXStartTypeString),
                                 @"timestamp" : @(OEXStartTypeTimestamp),
                                 @"empty" : @(OEXStartTypeNone)
                                 };
    NSNumber* result = [startTypes objectForKey:type] ?: @(OEXStartTypeNone);
    return result.integerValue;
}

NSString* NSStringForOEXStartType(OEXStartType type) {
    switch(type) {
    case OEXStartTypeString: return @"string";
    case OEXStartTypeTimestamp: return @"timestamp";
    case OEXStartTypeNone: return @"empty";
    }
}

@interface OEXCourseStartDisplayInfo ()

@property (strong, nonatomic, nullable) NSDate* date;
@property (copy, nonatomic, nullable) NSString* displayDate;
@property (assign, nonatomic) OEXStartType type;

@end

@implementation OEXCourseStartDisplayInfo

- (id)initWithDate:(NSDate *)date displayDate:(NSString *)displayDate type:(OEXStartType)type {
    self = [super init];
    if(self != nil) {
        self.date = date;
        self.displayDate = displayDate;
        self.type = type;
    }
    return self;
}

- (NSDictionary<NSString*, id>*)jsonFields {
    NSMutableDictionary<NSString*, NSObject*>* result = [[NSMutableDictionary alloc] init];
    [result setObjectOrNil:[OEXDateFormatting serverStringWithDate:self.date] forKey:@"start"];
    [result setObjectOrNil:self.displayDate forKey:@"start_display"];
    [result setObjectOrNil:NSStringForOEXStartType(self.type) forKey:@"start_type"];
    return result;
}

@end

@interface OEXCourse ()

@property (nonatomic, strong) OEXLatestUpdates* latest_updates;
@property (nonatomic, strong) NSDate* end;
@property (nonatomic, strong) OEXCourseStartDisplayInfo* start_display_info;
@property (nonatomic, copy) NSString* course_image_url;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* org;
@property (nonatomic, copy) NSString* video_outline;
@property (nonatomic, copy) NSString* course_id;
@property (nonatomic, copy) NSString* root_block_usage_key;
@property (nonatomic, copy) NSString* subscription_id;
@property (nonatomic, copy) NSString* number;
@property (nonatomic, copy) NSString* effort;
@property (nonatomic, copy) NSString* short_description;
@property (nonatomic, copy) NSString *intro_video_3rd_url;
@property (nonatomic, copy) NSString* overview_html;
@property (nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (nonatomic, copy) NSString* course_about;           // COURSE INFO
@property (nonatomic, strong) OEXCoursewareAccess* courseware_access;
@property (nonatomic, copy) NSString* discussionUrl;
@property (nonatomic, copy) NSDictionary<NSString*, CourseMediaInfo*>* mediaInfo;
@property (nonatomic, copy)NSString *moreDescription;//更多课程详情
@property (nonatomic, copy) NSNumber* listen_count;//报名人数
@property (nonatomic, copy) NSString* professor_username;//教授名字
@property (nonatomic, copy) NSNumber *course_price;//价格

@property (nonatomic,copy) NSNumber *give_coin; //购买课程赠送宝典
@property (nonatomic,copy) NSString *begin_at; //购买课程赠送宝典开始时间
@property (nonatomic,copy) NSString *end_at; //购买课程赠送宝典结束时间

@property (nonatomic,copy) NSNumber *is_eliteu_course;//是否付费的课程

@property (nonatomic,copy) NSNumber *course_status; //课程状态 1.未购买未试听 2.试听 3.试听已结束 4.已购买
@property (nonatomic,copy) NSString *trial_expire_at; //试听课程失效时间
@property (nonatomic,copy) NSNumber *trial_seconds;//剩余试听时间

@end

@implementation OEXCourse

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if(self != nil) {
        info = [info oex_replaceNullsWithEmptyStrings];
        
        self.end = [OEXDateFormatting dateWithServerString:[info objectForKey:@"end"]];
        NSDate* start = [OEXDateFormatting dateWithServerString:[info objectForKey:@"start"]];
        self.start_display_info = [[OEXCourseStartDisplayInfo alloc] initWithDate:start displayDate:[info objectForKey:@"start_display"] type:OEXStartTypeForString([info objectForKey:@"start_type"])];
        
        self.course_image_url = [info objectForKey:@"course_image"];
        self.name = [info objectForKey:@"name"];
        self.org = [info objectForKey:@"org"];
        self.video_outline = [info objectForKey:@"video_outline"];
        self.course_id = [info objectForKey:@"id"];
        self.root_block_usage_key = [info objectForKey:@"root_block_usage_key"];
        self.number = [info objectForKey:@"number"];
        self.effort = [info objectForKey:@"effort"];
        self.listen_count = [info objectForKey:@"listen_count"]; //报名人数
        self.course_price = [info objectForKey:@"course_price"];
        self.professor_username = [info objectForKey:@"professor_username"]; //教授名字
        self.short_description = [info objectForKey:@"short_description"];
        self.moreDescription = [[info objectForKey:@"description"] stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"]; //添加更多课程详情描述
        self.intro_video_3rd_url = [info objectForKey:@"intro_video_3rd_url"];
        self.overview_html = [info objectForKey:@"overview"];
        self.course_updates = [info objectForKey:@"course_updates"];
        self.course_handouts = [info objectForKey:@"course_handouts"];
        self.course_about = [info objectForKey:@"course_about"];
        self.subscription_id = [info objectForKey:@"subscription_id"];
        NSDictionary* accessInfo = [info objectForKey:@"courseware_access"];
        self.courseware_access = [[OEXCoursewareAccess alloc] initWithDictionary: accessInfo];
        NSDictionary* updatesInfo = [info objectForKey:@"latest_updates"];
        self.latest_updates = [[OEXLatestUpdates alloc] initWithDictionary:updatesInfo];
        self.discussionUrl = [info objectForKey:@"discussion_url"];
        
        self.give_coin = [info objectForKey:@"give_coin"];
        self.begin_at = [info objectForKey:@"begin_at"];
        self.end_at = [info objectForKey:@"end_at"];
        self.is_eliteu_course = [info objectForKey:@"is_eliteu_course"];
        
        self.course_status = [info objectForKey:@"course_status"];
        self.trial_expire_at = [info objectForKey:@"trial_expire_at"];
        self.trial_seconds = [info objectForKey:@"trial_seconds"];
        
        NSDictionary* mediaInfo = OEXSafeCastAsClass(info[@"media"], NSDictionary);
        
        NSMutableDictionary<NSString*, CourseMediaInfo*>* parsedMediaInfo = [[NSMutableDictionary alloc] init];
        [mediaInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString* type = OEXSafeCastAsClass(key, NSString);
            NSDictionary* content = OEXSafeCastAsClass(obj, NSDictionary);
            CourseMediaInfo* info = [[CourseMediaInfo alloc] initWithDict:content];
            [parsedMediaInfo setObjectOrNil:info forKey:type];
        }];
        self.mediaInfo = parsedMediaInfo;
        
        NSLog(@"课程详情 ---- %@",info);

    }
    return self;
}

- (BOOL)isStartDateOld {
    return [self.start_display_info.date oex_isInThePast];
}

- (BOOL)isEndDateOld {
    return [self.end oex_isInThePast];
}

- (CourseMediaInfo*)courseImageMediaInfo {
    return self.mediaInfo[@"course_image"];
}

- (CourseMediaInfo*)courseVideoMediaInfo {
    return self.mediaInfo[@"course_video"];
}

- (NSString*)courseImageURL {
    return self.course_image_url ?: self.courseImageMediaInfo.uri;
}

@end
