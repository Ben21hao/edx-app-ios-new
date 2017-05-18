//
//  TDAboutWeViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDAboutWeViewController.h"

@interface TDAboutWeViewController ()

@property (nonatomic,strong) UIImageView *mapImage;
@property (nonatomic,strong) UIImageView *eliteuImage;
@property (nonatomic,strong) UITextView *webTextView;
@property (nonatomic,strong) UILabel *verctionLabel;
@property (nonatomic,strong) UILabel *companyLabel;

@end

@implementation TDAboutWeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configView];
    [self setConstraint];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"ABOUT_APP", nil);
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
}

#pragma mark - UI
- (void)configView {
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.mapImage = [[UIImageView alloc] init];
    self.mapImage.image = [UIImage imageNamed:@"placeholderCourseCardImage"];
    [self.view addSubview:self.mapImage];
    
    self.eliteuImage = [[UIImageView alloc] init];
    self.eliteuImage.image = [UIImage imageNamed:@"edx_logo_login"];
    [self.view addSubview:self.eliteuImage];
    
    NSString *webSiteStr = [NSString stringWithFormat:@"%@：www.eliteu.cn",NSLocalizedString(@"WEBSITE_COMPANY", nil)];
    self.webTextView = [[UITextView alloc] init];
    self.webTextView.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.webTextView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.webTextView.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.webTextView.editable = NO;
    self.webTextView.showsVerticalScrollIndicator = NO;
    self.webTextView.scrollEnabled = NO;
    self.webTextView.text = webSiteStr;
    [self.view addSubview:self.webTextView];
    
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *version = infoDic[@"CFBundleShortVersionString"];
    NSString *versionStr = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"VERSION_APP", nil),version];
    
    self.verctionLabel = [self setLabelConstraint:versionStr];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger uniFlags = NSCalendarUnitYear;
    NSDateComponents *dateComponent = [calendar components:uniFlags fromDate:now];
    NSInteger year = [dateComponent year];
    NSString *yearStr = [NSString stringWithFormat:@"©%ld %@",(long)year,NSLocalizedString(@"COMPANY_NAME", nil)];
    
    self.companyLabel = [self setLabelConstraint:yearStr];
    self.companyLabel.numberOfLines = 0;
}

- (UILabel *)setLabelConstraint:(NSString *)title {
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:12];
    label.textColor = [UIColor colorWithHexString:colorHexStr9];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    [self.view addSubview:label];
    return label;
}

- (void)setConstraint {
    
    NSInteger height = 151;
    CGSize size = CGSizeMake(288, 122);
    NSInteger top = 58;
    if (TDWidth  > 320 && TDWidth < 400) {
        height = 159;
        size = CGSizeMake(313, 132);
        top = 68;
    } else if (TDWidth > 400) {
        height = 168;
        size = CGSizeMake(358, 151);
        top = 78;
    }
    [self.mapImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(top);
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.height.mas_equalTo(height);
    }];
    
    [self.eliteuImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mapImage.mas_centerX);
        make.top.mas_equalTo(self.mapImage.mas_top).offset(8);
        make.size.mas_equalTo(size);
    }];
    
    [self.webTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mapImage.mas_centerX);
        make.top.mas_equalTo(self.eliteuImage.mas_bottom).offset(18);
    }];
    
    [self.companyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_left).offset(18);
        make.right.mas_equalTo(self.view.mas_right).offset(-18);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(-18);
    }];
    
    [self.verctionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.bottom.mas_equalTo(self.companyLabel.mas_top).offset(-3);
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
