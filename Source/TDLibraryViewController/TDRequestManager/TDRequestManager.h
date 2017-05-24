//
//  TDRequestManager.h
//  edX
//
//  Created by Ben on 2017/5/8.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDRequestManager : NSObject

/*
 加入自己公司的课程
 */
- (void)addOwnCompanyCourse:(NSString *)course_id username:(NSString *)username companyID:(NSString *)company_id;
@property (nonatomic,copy) void(^addOwnCompanyCourseHandle)(NSInteger type);

@end
