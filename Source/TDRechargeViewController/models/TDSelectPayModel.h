//
//  TDSelectPayModel.h
//  edX
//
//  Created by Elite Edu on 16/12/4.
//  Copyright © 2016年 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDSelectPayModel : NSObject

@property (nonatomic,strong) NSString *imageStr;
@property (nonatomic,strong) NSString *payStr;
@property (nonatomic,assign) BOOL isSelected;
@property (nonatomic,strong) NSString *payType;

@end
