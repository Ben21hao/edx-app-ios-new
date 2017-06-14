//
//  TDEditeBottomView.m
//  edX
//
//  Created by Ben on 2017/6/13.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDEditeBottomView.h"
#import "edX-Swift.h"

@implementation TDEditeBottomView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setViewConstraint];
    }
    return self;
}

- (void)setViewConstraint {
     [self setBackgroundColor:[UIColor colorWithRed:62.0 / 255.0 green:66.0 / 255.0 blue:71.0 / 255.0 alpha:1.0]];
    
    float viewWidth = SCREEN_WIDTH;
    
    self.btn_Edit = [self setButtonStyle:[Strings edit] hidden:NO];
    [self.btn_Edit setFrame:CGRectMake(0, 0, viewWidth, 50)];
    [self addSubview:self.btn_Edit];
    
    self.btn_Cancel = [self setButtonStyle:[Strings cancel] hidden:YES];
    [self.btn_Cancel setFrame:CGRectMake(0, 0, (viewWidth - 2)/2 , 50)];
    [self addSubview:self.btn_Cancel];
    
    self.btn_Delete = [self setButtonStyle:[Strings delete] hidden:YES];
    [self.btn_Delete setFrame:CGRectMake(viewWidth / 2, 0, (viewWidth - 2)/2, 50)];
    [self.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
    self.btn_Delete.enabled = NO;
    [self addSubview:self.btn_Delete];
    
    self.imgSeparator = [[UIImageView alloc] initWithFrame:CGRectMake(viewWidth / 2 - 0.5, 0, 1, 50)];
    self.imgSeparator.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    self.imgSeparator.hidden = YES;
    [self addSubview:self.imgSeparator];
}

- (UIButton *)setButtonStyle:(NSString *)title hidden:(BOOL)hidden {
    
    UIButton *button = [[UIButton alloc] init];
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button setIsAccessibilityElement:YES];
    [button accessibilityActivate];
    
    button.hidden = hidden;
    
    return button;
}


@end
