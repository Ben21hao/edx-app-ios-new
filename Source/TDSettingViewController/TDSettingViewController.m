//
//  TDSettingViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDSettingViewController.h"
#import "TDSettingCell.h"

#import "TDAboutWeViewController.h"

#import "edX-Swift.h"
#import "WYAlertView.h"


@interface TDSettingViewController () <UITableViewDataSource, UITableViewDelegate,WYAlertViewDelegate>

@property (strong, nonatomic) UILabel *titleL;//自定义标题
@property (nonatomic,strong) UITableView *tableView;
@property(nonatomic,strong) NSString *download_url;

@end

@implementation TDSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTableViewConstraint];
    
    self.titleL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.titleL.text = [Strings settings];
    self.titleL.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.titleL.textColor = [UIColor whiteColor];
    self.navigationItem.titleView = self.titleL;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - UI
- (void)setTableViewConstraint {
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.scrollEnabled = NO; 
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
}


#pragma mark - tableview Delegate 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    tableView.separatorInset = UIEdgeInsetsZero;
    
    if (indexPath.row == 0) {
        TDSettingCell *cell = [[TDSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDWifiCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
        
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingCell"];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
        cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
        cell.textLabel.text = NSLocalizedString(@"ABOUT_APP", nil);
        return cell;
    } 
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 68;
    } else {
        return 48;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        [self gotoAboutViewController];
    }
}

#pragma mark - 关于
- (void)gotoAboutViewController {
    TDAboutWeViewController *aboutVc = [[TDAboutWeViewController alloc] init];
    [self.navigationController pushViewController:aboutVc animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

#pragma mark --WYAlertViewDelegate
- (void)beginDownLoad{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.download_url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
