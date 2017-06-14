//
//  TDBaseScrollView.m
//  edX
//
//  Created by Elite Edu on 17/3/16.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDBaseScrollView.h"

@implementation TDBaseScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
//    NSLog(@" ---->>> 横向滑动 %f",self.contentOffset.x);
    if (otherGestureRecognizer.state == UIGestureRecognizerStateBegan && self.contentOffset.x == 0) {
        return YES;
    }
    return NO;
}

@end
