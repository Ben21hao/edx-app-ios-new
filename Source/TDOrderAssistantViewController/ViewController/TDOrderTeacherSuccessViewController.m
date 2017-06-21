//
//  TDOrderTeacherSuccessViewController.m
//  edX
//
//  Created by Elite Edu on 17/3/1.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDOrderTeacherSuccessViewController.h"
#import "TDRechargeViewController.h"

@interface TDOrderTeacherSuccessViewController () <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UIView *headerView;
@property (nonatomic,strong) UILabel *imageLabel;
@property (nonatomic,strong) UIButton *topButton;
@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UIView *footerView;
@property (nonatomic,strong) UIButton *moreOrderButton;
@property (nonatomic,strong) UIButton *rechargeButton;

@property (nonatomic,strong) NSString *failStr;

@property (nonatomic,strong) UIButton *leftButton;
@property (nonatomic,strong) TDBaseToolModel *toolModel;

@end

@implementation TDOrderTeacherSuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.title = self.isSuccess ? NSLocalizedString(@"APPOINTMENT_STATUS", nil) : NSLocalizedString(@"APPOINTMENT_STATUS", nil);
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.toolModel = [[TDBaseToolModel alloc] init];
    [self setLeftNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.failType == 401) {
        self.failStr = NSLocalizedString(@"APPOINTMENT_SELF", nil);
        
    }  else if (self.failType == 402) {
        self.failStr = NSLocalizedString(@"ENROLL_COURSE_FIRST", nil);
        
    }  else if (self.failType == 403) {
        self.failStr = NSLocalizedString(@"CURRENT_TIME_EARILER", nil);
        
    }  else if (self.failType == 406) {
        self.failStr = NSLocalizedString(@"NO_ENOUGH_COINS", nil);
        
    }  else if (self.failType == 407) {
        self.failStr = NSLocalizedString(@"NO_SCHEDULE", nil);
        
    }  else if (self.failType == 408) {
        self.failStr = NSLocalizedString(@"SELECT_OTHER_PERIOD", nil);
        
    }  else {
        self.failStr = NSLocalizedString(@"UNABLE_APPOINTMENT", nil);
        NSLog(@"预约失败 -- %ld",(long)self.failType);
    }
    
    [self setviewConstraint];
}

#pragma mark - 导航栏左边按钮
- (void)setLeftNavigationBar {
    
    self.leftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [self.leftButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    self.leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    [self.leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.leftButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftButton];
    
}

- (void)backButtonAction:(UIButton *)sender {
    NSInteger index = self.whereFrom == 1 ? 2 : 1;
    [self.navigationController popToViewController:self.navigationController.childViewControllers[index] animated:YES];
}

#pragma mark - 按钮
- (void)moreOrderButtonAction:(UIButton *)sender {//重新预约
    NSInteger index = self.whereFrom == 1 ? 3 : 2;
    [self.navigationController popToViewController:self.navigationController.childViewControllers[index] animated:YES];
}

- (void)rechargeButtonAction:(UIButton *)sender {
    if (self.failType == 402) {//加入课程
        NSInteger index = self.whereFrom == 1 ? 2 : 1;
        [self.navigationController popToViewController:self.navigationController.childViewControllers[index] animated:YES];
   
    } else {//充值
        TDRechargeViewController *rechargeVC = [[TDRechargeViewController alloc] init];
        rechargeVC.username = self.username;
        rechargeVC.whereFrom = 1;
        [self.navigationController pushViewController:rechargeVC animated:YES];
    }
}

#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.isSuccess ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDCreateOrderResultCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TDCreateOrderResultCell"];
    }
    cell.userInteractionEnabled = NO;
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.detailTextLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"RESERCED_PERIOD", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",self.timeStr];

            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"PREPAID_COIS", nil);
            cell.detailTextLabel.attributedText = [self.toolModel setDetailString:[NSString stringWithFormat:@"%@%@",self.iconStr,NSLocalizedString(@"COINS_VALUE", nil)] withFont:14 withColorStr:colorHexStr9];
            break;
        case 2:
        {
            NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"QUETIONS_DESCRIPTION", nil)] attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr10]}];
            NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:self.quetionStr attributes:@{NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr9]}];
            [str1 appendAttributedString:str2];
            cell.textLabel.attributedText = str1;
        }
            break;

        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2) {
        CGSize size = [self.toolModel getSringSize:self.quetionStr withFont:14];
        return 58 + size.height;
    } else {
        return 48;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    if (self.isSuccess) {
        UIView *leftLine = [[UIView alloc] init];
        leftLine.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [view addSubview:leftLine];
        
        UIView *rightLine = [[UIView alloc] init];
        rightLine.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [view addSubview:rightLine];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        titleLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
        titleLabel.text = NSLocalizedString(@"APPOINTMENT_DETAILS", nil);
        [view addSubview:titleLabel];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(view.mas_centerY);
            make.centerX.mas_equalTo(view.mas_centerX);
            make.height.mas_equalTo(28);
        }];
        
        [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(view.mas_left).offset(28);
            make.right.mas_equalTo(titleLabel.mas_left).offset(-18);
            make.centerY.mas_equalTo(view.mas_centerY);
            make.height.mas_equalTo(1);
        }];
        
        [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(view.mas_right).offset(-28);
            make.left.mas_equalTo(titleLabel.mas_right).offset(18);
            make.centerY.mas_equalTo(view.mas_centerY);
            make.height.mas_equalTo(1);
        }];
    }
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.isSuccess ? 58 : 0;
}


#pragma mark - UI
- (void)setviewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(self.view);
    }];
    
    self.tableView.tableHeaderView = [self setTableViewHeaderView];
    self.tableView.tableFooterView  = [self settableViewFooterView];
    
}

- (UIView *)setTableViewHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 98)];
    self.headerView.backgroundColor = [UIColor whiteColor];
    
    self.topButton = [[UIButton alloc] init];
    self.topButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    [self.topButton setTitleColor:[UIColor colorWithHexString:colorHexStr10] forState:UIControlStateNormal];
    [self.topButton setTitle:self.isSuccess? NSLocalizedString(@"APPOINTMENT_HAVE", nil) : NSLocalizedString(@"UNABLE_APPOINTMENT", nil) forState:UIControlStateNormal];
    [self.headerView addSubview:self.topButton];
    
    self.imageLabel = [[UILabel alloc] init];
    self.imageLabel.font = [UIFont fontWithName:@"FontAwesome" size:20];
    self.imageLabel.text = self.isSuccess ? @"\U0000f058" : @"\U0000f06a";
    self.imageLabel.textColor = [UIColor colorWithHexString:colorHexStr1];
    [self.headerView addSubview:self.imageLabel];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.messageLabel.text = self.isSuccess ? NSLocalizedString(@"ATTENTION_MESSAGE", nil) : self.failStr;
    [self.headerView addSubview:self.messageLabel];
    
    [self.topButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.headerView.mas_centerX).offset(6);
        make.bottom.mas_equalTo(self.headerView.mas_centerY).offset(-5);
    }];
    
    [self.imageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.topButton.mas_left).offset(-6);
        make.centerY.mas_equalTo(self.topButton.mas_centerY);
    }];
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(8);
        make.right.mas_equalTo(self.headerView.mas_right).offset(-8);
        make.top.mas_equalTo(self.headerView.mas_centerY).offset(5);
    }];
    
    return self.headerView;
}
- (UILabel *)setLabelConstraint:(NSString *)title {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithName:@"OpenSans" size:14];
    label.textColor = [UIColor colorWithHexString:colorHexStr10];
    label.text = title;
    return label;
}

- (UIView *)settableViewFooterView {
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 88)];
    self.footerView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    if (self.isSuccess) {
        self.moreOrderButton = [self setButton:NSLocalizedString(@"NEW_APPOINTMENT", nil)];
        [self.moreOrderButton addTarget:self action:@selector(moreOrderButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.footerView addSubview:self.moreOrderButton];
        
        [self.moreOrderButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.footerView.mas_left).offset(18);
            make.right.mas_equalTo(self.footerView.mas_right).offset(-18);
            make.centerY.mas_equalTo(self.footerView.mas_centerY);
            make.height.mas_equalTo(42);
        }];
        
    } else {
        self.moreOrderButton = [self setButton:NSLocalizedString(@"RESCHEDULE_APPOINTMENT", nil)];
        [self.moreOrderButton addTarget:self action:@selector(moreOrderButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.footerView addSubview:self.moreOrderButton];
        
        [self.moreOrderButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.footerView.mas_left).offset(18);
            make.centerY.mas_equalTo(self.footerView.mas_centerY);
            make.size.mas_equalTo(CGSizeMake((TDWidth - 58) / 2, 39));
        }];

        self.rechargeButton = [self setButton:self.failType == 402 ? NSLocalizedString(@"ENROLL_COURSE", nil) : NSLocalizedString(@"TOP_UP_MONEY", nil)];
        [self.rechargeButton addTarget:self action:@selector(rechargeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.footerView addSubview:self.rechargeButton];
        
        [self.rechargeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.footerView.mas_right).offset(-18);
            make.centerY.mas_equalTo(self.footerView.mas_centerY);
            make.size.mas_equalTo(CGSizeMake((TDWidth - 58) / 2, 39));
        }];
    }
    
    return self.footerView;
}

- (UIButton *)setButton:(NSString *)title {
    
    UIButton *button = [[UIButton alloc] init];
    button.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    button.layer.cornerRadius = 4.0;
    button.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    return button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
