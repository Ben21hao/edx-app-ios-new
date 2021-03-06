//
//  TDTeachOrderDetailViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/14.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeachOrderDetailViewController.h"
#import "TDSuTitleCell.h"

@interface TDTeachOrderDetailViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;

@end

@implementation TDTeachOrderDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.titleViewLabel.text = @"订单详情";
    [self setViewConstraint];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 4) {
        return self.model.order_time_grap.length == 0 ? 0 : 1;
    } else if (section == 7) {
        return self.model.real_cost_coin.length == 0 ? 0 : 1;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 9) {

        TDSuTitleCell *cell = [[TDSuTitleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDSubtitleCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLabel.text = @"咨询问题";
        cell.subTitileLabel.text = self.model.question;
        return cell;
        
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDTeacherMessagCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TDTeacherMessagCell"];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
        cell.detailTextLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        cell.detailTextLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
        
        TDBaseToolModel *toolModel = [[TDBaseToolModel alloc] init];
        switch (indexPath.section) {
            case 0:
                cell.textLabel.text = @"课程";
                cell.detailTextLabel.text = self.model.course_display_name;
                break;
            case 1:
                cell.textLabel.text = @"服务订单";
                cell.detailTextLabel.text = self.model.id;
                break;
            case 2:
                cell.textLabel.text = @"助教";
                cell.detailTextLabel.text = self.model.assistant_name;
                break;
            case 3:
                cell.textLabel.text = @"服务类型";
                cell.detailTextLabel.text = [self.model.order_type intValue] == 1 ? @"预约服务" : @"即时服务";
                break;
            case 4:
                cell.textLabel.text = @"预约时间";
                cell.detailTextLabel.text = self.model.order_time_grap;
                break;
            case 5:
                cell.textLabel.text = @"服务时间";
                cell.detailTextLabel.text = self.model.service_time;
                break;
            case 6:
                cell.textLabel.text = @"预付宝典";
                cell.detailTextLabel.attributedText = [toolModel setDetailString:[NSString stringWithFormat:@"%.2f宝典",[self.model.cost_coin floatValue]] withFont:14 withColorStr:colorHexStr9];
                break;
            case 7:
                cell.textLabel.text = @"实付宝典";
                cell.detailTextLabel.attributedText = [toolModel setDetailString:[NSString stringWithFormat:@"%.2f宝典",[self.model.real_cost_coin floatValue]]withFont:14 withColorStr:colorHexStr9];
                break;
            case 8:
                cell.textLabel.text = @"状态";
                cell.detailTextLabel.text = self.statusStr;
                break;
            default:
                break;
        }
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDBaseToolModel *toolModel = [[TDBaseToolModel alloc] init];
    CGSize size = [toolModel getSringSize:self.model.question withFont:14];
    
    if (indexPath.section == 9) {
        return 55 + size.height;
    }
    return 53;
}


#pragma mark - UI
- (void)setViewConstraint {
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
