//
//  WYAlertView.m
//  WYAlertView
//
//  Created by wy on 16/5/11.
//  Copyright © 2016年 wy. All rights reserved.
//
#import "WYAlertView.h"
#import "UIColor+extend.h"
#import "UIColor+JHHexColor.h"

// 设置警告框的长和宽
#define SCREENSIZE ([UIScreen mainScreen].bounds.size)
#define Alertwidth (TDWidth * 5.0/6.0)
#define Alertheigth (Alertwidth*4.0/5.0)
//上下间隙
#define WYHeigthGap 16.0
// 按钮的高度
#define WYButtonHeigth 40.0f
//左右间隙
#define WYGapX 10.0

#define ScreenWideh ([UIScreen mainScreen].bounds.size)
@interface WYAlertView ()<UITextFieldDelegate>
{
    BOOL isShow;
    CGFloat _height;
}

@property (nonatomic, strong) UIView *whiteView;
@property (nonatomic, strong) UILabel *alertTitleLabel;
@property (nonatomic, strong) UILabel *alertContentLabel;

@property (nonatomic, strong) UIView *backimageView;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic,strong) UIView *sepV;
@end

@implementation WYAlertView

+ (CGFloat)alertWidth
{
    return Alertwidth;
}

+ (CGFloat)alertHeight
{
    return Alertheigth;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
+(WYAlertView*)showmessage:(NSString *)message subtitle:(NSString *)subtitle cancelbutton:(NSString *)cancle
{
    WYAlertView *alert = [[WYAlertView alloc] initWithTitle:message contentText:subtitle cancelButtonTitle:nil rightButtonTitle:cancle iconString:nil textField:YES headerView:nil];
    [alert show];
    alert.rightBlock = ^() {
    };
    alert.dismissBlock = ^() {
    };
    return alert;
}

- (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font maxW:(CGFloat)maxW
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = font;
    CGSize maxSize = CGSizeMake(maxW, MAXFLOAT);
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading attributes:attrs context:nil].size;
}
//带有头部背景图片
- (id)initHeaderImageAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)leftTitle rightButtonTitle:(NSString *)rigthTitle imageName:(NSString *)imageName
{
    return [self initWithTitle:title contentText:message cancelButtonTitle:leftTitle rightButtonTitle:rigthTitle iconString:nil textField:NO headerView:imageName];
}
//纯文字
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)leftTitle rightButtonTitle:(NSString *)rigthTitle
{
    return [self initWithTitle:title contentText:message cancelButtonTitle:leftTitle rightButtonTitle:rigthTitle iconString:nil textField:NO headerView:nil];
}
//带有分享图片
- (id)initIconAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)leftTitle rightButtonTitle:(NSString *)rigthTitle imageName:(NSString *)imageName
{
    return [self initWithTitle:title contentText:message cancelButtonTitle:leftTitle rightButtonTitle:rigthTitle iconString:imageName textField:NO headerView:nil];
}
//带有输入框
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)leftTitle rightButtonTitle:(NSString *)rigthTitle beTextField:(BOOL)isTextField
{
    return [self initWithTitle:title contentText:message cancelButtonTitle:leftTitle rightButtonTitle:rigthTitle iconString:nil textField:isTextField headerView:nil];
}
//带有输入框与分享图片
- (id)initIconTextAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)leftTitle rightButtonTitle:(NSString *)rigthTitle imageName:(NSString *)imageName beTextField:(BOOL)isTextField{
    return [self initWithTitle:title contentText:message cancelButtonTitle:leftTitle rightButtonTitle:rigthTitle iconString:imageName textField:isTextField headerView:nil];
}

- (id)initWithTitle:(NSString *)title
        contentText:(NSString *)content
  cancelButtonTitle:(NSString *)leftTitle
   rightButtonTitle:(NSString *)rigthTitle
         iconString:(NSString *)iconString
          textField:(BOOL)hasText
         headerView:(NSString *)headImgString
{
    if (self = [super init]) {
        
        _whiteView = [[UIView alloc] initWithFrame:CGRectMake((SCREENSIZE.width - Alertwidth) * 0.5, (SCREENSIZE.height - Alertheigth) * 0.5, Alertwidth, Alertheigth)];
        _whiteView.backgroundColor = [UIColor getColor:@"ffffff"];
        _whiteView.layer.cornerRadius = 5.0;
        _whiteView.layer.masksToBounds = YES;
        [self addSubview:_whiteView];
        self.backgroundColor = [UIColor getColor:@"000000" alpha:0.6];
        
        UIImageView * headImage = [[UIImageView alloc] init];
        if (headImgString!=nil) {
//            CGFloat headImgH = 0;
            if ([[headImgString lowercaseString] hasPrefix:@"http"]) {
//                [headImage sd_setImageWithURL:[NSURL URLWithString:headImgString] placeholderImage:[UIImage imageNamed:@"imageDefault"]];
                //headImgH = headImg.size.height*Alertwidth/headImg.size.width;
//                headImgH = 60;
            }else{
                UIImage * img = [UIImage imageNamed:headImgString];
                if (img!=nil) {
                    UIImage * img = [UIImage imageNamed:headImgString];
                    [headImage setImage:img];
                }
//                headImgH =img!=nil?(headImage.image.size.height*Alertwidth/headImage.image.size.width):0;
            }
//            headImage.frame = CGRectMake(0, 0, Alertwidth, headImgH);
            CGFloat headW = 60;
            headImage.frame = CGRectMake(Alertwidth/2 - headW/2, 0 , headW, headW-2);
            [_whiteView addSubview:headImage];
            //添加分割线
            CGFloat x = ([UIScreen mainScreen].bounds.size.width - Alertwidth) * 0.001;
            UIView *sepV = [[UIView alloc] initWithFrame:CGRectMake(x, headW-2, Alertwidth, 0.5)];
            sepV.backgroundColor = [UIColor lightGrayColor];
            [_whiteView addSubview:sepV];
        }
        
        if (title==nil || title.length<1) {
            title = nil;
        }
        CGSize titleSize = [self sizeWithText:title font:[UIFont systemFontOfSize:16.0f] maxW:Alertwidth-20];
   
        CGFloat titleX = WYGapX;
        CGFloat titleW = Alertwidth-WYGapX*2;
        CGFloat titleY = headImgString!=nil?(CGRectGetMaxY(headImage.frame)+WYGapX):WYGapX*2;
        CGFloat titleH = titleSize.height>38?39:titleSize.height;
        
        self.alertTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleX, titleY, titleW, titleH)];
        self.alertTitleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        self.alertTitleLabel.textColor=[UIColor colorWithHexString:colorHexStr10];
        self.alertTitleLabel.numberOfLines = 0;
        self.alertTitleLabel.textAlignment = NSTextAlignmentCenter;
        [_whiteView addSubview:self.alertTitleLabel];
        
        //添加分割线
        CGFloat titleMaxY = CGRectGetMaxY(self.alertTitleLabel.bounds);
        self.sepV = [[UIView alloc] initWithFrame:CGRectMake(0, titleMaxY + 35, _whiteView.bounds.size.width, 0.5)];
        _sepV.backgroundColor = [UIColor getColor:@"000000" alpha:0.1];
        [_whiteView addSubview:_sepV];

        CGFloat Y = titleSize.height>0?CGRectGetMaxY(self.alertTitleLabel.frame)+WYGapX*2:CGRectGetMaxY(self.alertTitleLabel.frame);
        CGFloat imageWidth = 0;
        if (iconString!=nil) {
            imageWidth=60;
            self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(WYGapX, Y, imageWidth, imageWidth)];
//            self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,10,10)];
            [self.iconImageView setBackgroundColor:[UIColor clearColor]];
            if ([[iconString lowercaseString] hasPrefix:@"http"]) {
//                [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:iconString] placeholderImage:[UIImage imageNamed:@"imageDefault"]];
            }
            else
            {
                [self.iconImageView setImage:[UIImage imageNamed:iconString]];
            }
            [_whiteView addSubview:self.iconImageView];
        }else{
            imageWidth = 0;
        }
        
        CGFloat contentLabelX = iconString!=nil?(imageWidth+WYGapX*2):(imageWidth+WYGapX);
        CGFloat contentLabelW = iconString!=nil?(Alertwidth - imageWidth-WYGapX*3):(Alertwidth - imageWidth-WYGapX*2);
        CGFloat contentLabelY = Y;
        CGSize size = [self sizeWithText:content font:[UIFont systemFontOfSize:15.0f] maxW:contentLabelW];
        
        CGFloat contentLabelH = (iconString!=nil)?
        (size.height>imageWidth?
         imageWidth:size.height):
        (size.height>(SCREENSIZE.height/4))?
        SCREENSIZE.height/4:size.height;
        
        self.alertContentLabel = [[UILabel alloc] init];
        self.alertContentLabel.numberOfLines = 0;
        self.alertContentLabel.textColor = [UIColor getColor:@"000000" alpha:0.7];
        self.alertContentLabel.font = [UIFont systemFontOfSize:15.0f];
        [_whiteView addSubview:self.alertContentLabel];
        //设置对齐方式
        self.alertContentLabel.textAlignment = NSTextAlignmentCenter;
        if (iconString!=nil) {
            self.alertContentLabel.textAlignment = NSTextAlignmentLeft;
        }
        if (headImgString!=nil) {
            self.alertContentLabel.textAlignment = NSTextAlignmentLeft;
        }
        UIScrollView * scrollView = [[UIScrollView alloc] init];
        if (contentLabelH==(SCREENSIZE.height/4)) {
            scrollView.frame = CGRectMake(contentLabelX, contentLabelY, contentLabelW, contentLabelH);
            [scrollView setContentSize:CGSizeMake(contentLabelW, size.height)];
            self.alertContentLabel.frame = CGRectMake(0, 0, contentLabelW, size.height);
            [scrollView addSubview:self.alertContentLabel];
            [_whiteView addSubview:scrollView];
            
        }else{
            self.alertContentLabel.frame = CGRectMake(contentLabelX, contentLabelY, contentLabelW, contentLabelH);
            [_whiteView addSubview:self.alertContentLabel];
        }
        
        if (hasText) {
            CGFloat FieldX = WYGapX;
            CGFloat FieldY = (iconString!=nil)? CGRectGetMaxY(self.iconImageView.frame)+WYHeigthGap : ((contentLabelH==(SCREENSIZE.height/4) ? CGRectGetMaxY(scrollView.frame)+WYHeigthGap : CGRectGetMaxY(self.alertContentLabel.frame)+WYHeigthGap));
            CGFloat FieldW = Alertwidth-25;
            CGFloat FieldH = hasText ? 41 : 0;
            
            self.text = [[JHTextField alloc] initWithFrame:CGRectMake(FieldX, FieldY, FieldW, FieldH)];
            self.text.borderStyle = UITextBorderStyleNone;
            self.text.layer.cornerRadius = 5.0;
            self.text.layer.masksToBounds = YES;
            self.text.layer.borderWidth = 0.5;
            self.text.layer.borderColor = [[UIColor getColor:@"000000" alpha:0.1] CGColor];
            self.text.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 3, WYGapX, 30)];
            self.text.leftViewMode = UITextFieldViewModeAlways;
            self.text.backgroundColor = [UIColor getColor:@"f9f8f9"];
            [self.text setTextColor:[UIColor getColor:@"000000" alpha:0.6]];
            self.text.placeholder = NSLocalizedString(@"PHONE_OR_EMAIL", nil);
            [self.text setValue:[UIColor getColor:@"000000" alpha:0.5] forKeyPath:@"_placeholderLabel.textColor"];
            [self.text setValue:[UIFont systemFontOfSize:14] forKeyPath:@"_placeholderLabel.font"];
            self.text.delegate = self;
            [_whiteView addSubview:self.text];
        }
        
        CGRect leftbtnFrame;
        CGRect rightbtnFrame;
        CGFloat btnY = hasText?CGRectGetMaxY(self.text.frame)+WYHeigthGap : (((contentLabelH==(SCREENSIZE.height/4)) ? CGRectGetMaxY(scrollView.frame)+WYHeigthGap : CGRectGetMaxY(self.alertContentLabel.frame)+WYHeigthGap));
        
        if (leftTitle !=nil && rigthTitle==nil) {//只有左边按钮
            leftbtnFrame = CGRectMake(0, btnY, Alertwidth, WYButtonHeigth);
            rightbtnFrame = CGRectMake(CGRectGetMaxX(leftbtnFrame), btnY, 0, WYButtonHeigth);
            
        }else if (leftTitle==nil && rigthTitle!=nil){//只有右边按钮
            leftbtnFrame = CGRectMake(0, btnY, 0, WYButtonHeigth);
            rightbtnFrame = CGRectMake(CGRectGetMaxX(leftbtnFrame), btnY, Alertwidth, WYButtonHeigth);
            
        }else {//两个按钮都有
            
            leftbtnFrame = CGRectMake(0,btnY,Alertwidth * 0.5,WYButtonHeigth);
            rightbtnFrame = CGRectMake(Alertwidth * 0.5,btnY,Alertwidth * 0.5,WYButtonHeigth);
        }
        self.leftbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.leftbtn.frame = leftbtnFrame;
        [self.leftbtn setTitle:leftTitle forState:UIControlStateNormal];
        self.leftbtn.titleLabel.font = [UIFont systemFontOfSize:17];
        [self.leftbtn setTitleColor:[UIColor colorWithHexString:colorHexStr9] forState:UIControlStateNormal];
        [self.leftbtn addTarget:self action:@selector(leftbtnclicked:) forControlEvents:UIControlEventTouchUpInside];
        [_whiteView addSubview:self.leftbtn];
        
        self.rightbtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.rightbtn.frame = rightbtnFrame;
        [self.rightbtn setTitle:rigthTitle forState:UIControlStateNormal];
        self.rightbtn.titleLabel.font = [UIFont systemFontOfSize:17];
        [self.rightbtn setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
        [self.rightbtn addTarget:self action:@selector(rightbtnclicked:) forControlEvents:UIControlEventTouchUpInside];
        [_whiteView addSubview:self.rightbtn];
        
        UIView *topview = [[UIView alloc] initWithFrame:CGRectMake(0, btnY-0.5, Alertwidth, 0.5)];
        [topview setBackgroundColor:[UIColor getColor:@"000000" alpha:0.1]];
        
        UIView * centerView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftbtnFrame), btnY-1, 0.5, WYButtonHeigth+5)];
        [centerView setBackgroundColor:[UIColor getColor:@"000000" alpha:0.1]];
        centerView.hidden = (rigthTitle==nil||leftTitle==nil) ? YES : NO;
        [_whiteView addSubview:topview];
        [_whiteView addSubview:centerView];
        
        self.alertTitleLabel.text = title;
        self.alertContentLabel.text = content;
        
        self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        
        _height = CGRectGetMaxY(self.rightbtn.frame);
        if (_height>=SCREENSIZE.height) {
            _height = SCREENSIZE.height/2;
        }
        CGFloat whiteViewX = (SCREENSIZE.width - Alertwidth) * 0.5;
        CGFloat whiteViewY = (_height>=SCREENSIZE.height)?0:(SCREENSIZE.height - _height) * 0.5;
        CGFloat whiteViewW = Alertwidth;
        CGFloat whiteViewH = _height;
        _whiteView.frame = CGRectMake(whiteViewX, whiteViewY, whiteViewW, whiteViewH);
        
    }
    return self;
}
- (void)leftbtnclicked:(id)sender
{
    if (self.leftBlock) {
        self.leftBlock();
    }
    [self dismissAlert];
}
#pragma mark --- rightBtn
- (void)rightbtnclicked:(id)sender
{
    if (self.rightBlock) {
       self.rightBlock();
    }
    if (!self.isRightExist) {
        [self dismissAlert];
//        NSLog(@"点了");
//        if ([self.delegate respondsToSelector:@selector(beginDownLoad)]) {
//            [self.delegate beginDownLoad];
//        }
//        ViewController *vc = [[ViewController alloc] init];
//        [vc beginDownLoad];
    }
}
- (void)show
{   //获取第一响应视图视图
    if (isShow) {
        return;
    }
    UIWindow* tempWindow = [UIApplication sharedApplication].keyWindow;//[[[UIApplication sharedApplication] windows] lastObject];
    //    self.frame = CGRectMake((CGRectGetWidth(topVC.view.bounds) - Alertwidth) * 0.5-30, (CGRectGetHeight(topVC.view.bounds) - _height) * 0.5-20, Alertwidth, _height);
    [tempWindow addSubview:self];
    self.alpha=0;
//    tempWindow = nil;
    isShow = YES;
}
-(void)setLeftColor:(UIColor *)leftColor{
//    [self.leftbtn setTitleColor:leftColor forState:UIControlStateNormal];
    [self.leftbtn setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
}
-(void)setRightColor:(UIColor *)rightColor{
//    [self.rightbtn setTitleColor:rightColor forState:UIControlStateNormal];
    [self.rightbtn setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    
}
-(void)setContentColor:(UIColor *)contentColor{
    self.alertContentLabel.textColor = contentColor;
}
-(void)setTitleColor:(UIColor *)titleColor{
    self.alertTitleLabel.textColor=titleColor;
}
-(void)setTitle:(NSString *)title{
    self.alertTitleLabel.text=title;
}
-(void)setMessage:(NSString *)message{
    self.alertContentLabel.text = message;
}

- (void)dismissAlert
{
    isShow = NO;
    [self removeFromSuperview];
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}

- (UIViewController *)appRootViewController
{
    UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *topVC = appRootVC;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)removeFromSuperview
{
    [self.backimageView removeFromSuperview];
    self.backimageView = nil;
    //UIViewController *topVC = [self appRootViewController];
    //CGRect afterFrame = CGRectMake((CGRectGetWidth(topVC.view.bounds) - Alertwidth) * 0.5+30, (CGRectGetHeight(topVC.view.bounds) - Alertheigth) * 0.5-30, Alertwidth, _height);
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        //self.frame = afterFrame;
        self.alpha=0;
    } completion:^(BOOL finished) {
        [super removeFromSuperview];
    }];
}
//添加新视图时调用（在一个子视图将要被添加到另一个视图的时候发送此消息）
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview == nil) {
        return;
    }
    //     获取根控制器
    UIViewController *topVC = [self appRootViewController];
    
    if (!self.backimageView) {
        self.backimageView = [[UIView alloc] initWithFrame:topVC.view.bounds];
        self.backimageView.backgroundColor = [UIColor clearColor];
        self.backimageView.alpha = 0.6f;
        self.backimageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    //加载背景背景图,防止重复点击
    [topVC.view addSubview:self.backimageView];
    //CGRect afterFrame = CGRectMake((CGRectGetWidth(topVC.view.bounds) - Alertwidth) * 0.5, (CGRectGetHeight(topVC.view.bounds) - Alertheigth) * 0.5, Alertwidth, Alertheigth);
    CGRect afterFrame = CGRectMake(0, 0, SCREENSIZE.width, SCREENSIZE.height);
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionShowHideTransitionViews animations:^{
        self.frame = afterFrame;
        //self.alpha=0.9;
    } completion:^(BOOL finished) {
        self.alpha=1;
    }];
    [super willMoveToSuperview:newSuperview];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [UIView animateWithDuration:0.3 animations:^{
        [self.whiteView setFrame:CGRectMake((SCREENSIZE.width - Alertwidth) * 0.5, (SCREENSIZE.height - _height) * 0.5-50, Alertwidth, _height)];
    }];
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [UIView animateWithDuration:0.3 animations:^{
        [self.whiteView setFrame:CGRectMake((SCREENSIZE.width - Alertwidth) * 0.5, (SCREENSIZE.height - _height) * 0.5, Alertwidth, _height)];
    }];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.text resignFirstResponder];
}

@end

