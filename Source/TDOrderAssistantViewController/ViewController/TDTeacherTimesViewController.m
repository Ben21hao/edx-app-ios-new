//
//  TDTeacherTimesViewController.m
//  edX
//
//  Created by Elite Edu on 17/3/1.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeacherTimesViewController.h"
#import "TDCreateOrderViewController.h"
#import "TDTeacherTimeCell.h"
#import "TDTimeModel.h"

#import <MJExtension/MJExtension.h>

@interface TDTeacherTimesViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,strong) NSMutableArray *timeArray;

@property (nonatomic,strong) UIView *headerView;
@property (nonatomic,strong) UIView *footerView;
@property (nonatomic,strong) UIButton *frontButton;
@property (nonatomic,strong) UIButton *behindButton;
@property (nonatomic,strong) UILabel *timesLabel;
@property (nonatomic,strong) UILabel *messageLabel;

@property (nonatomic,strong) UILabel *nullLabel;
@property (nonatomic,strong) UIView *loadingView;

@property (nonatomic,strong) NSString *dateStr;
@property (nonatomic,assign) NSInteger addDay;
@property (nonatomic,assign) NSInteger typeNum;
@property (nonatomic,strong) NSString *starTimeStr; //预约开始时间
@property (nonatomic,strong) NSString *endTimeStr; //预约结束时间
@property (nonatomic,strong) NSMutableArray *selectArray;

@end

@implementation TDTeacherTimesViewController

- (NSMutableArray *)timeArray {
    if (!_timeArray) {
        _timeArray = [[NSMutableArray alloc] init];
    }
    return _timeArray;
}

- (NSMutableArray *)selectArray {
    if (!_selectArray) {
        _selectArray = [[NSMutableArray alloc] init];
    }
    return _selectArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"SELECT_PERIOD", nil);
    [self.rightButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    
    WS(weakSelf);
    self.rightButtonHandle = ^(){ //确定
        
        if (self.selectArray.count > 0) {
            
            [weakSelf joinTimeStr];
            
            TDCreateOrderViewController *createOrderVc = [[TDCreateOrderViewController alloc] init];
            createOrderVc.whereFrom = weakSelf.whereFrom;
            createOrderVc.starTimeStr = weakSelf.starTimeStr;
            createOrderVc.endTimeStr = weakSelf.endTimeStr;
            createOrderVc.dateStr = weakSelf.dateStr;
            createOrderVc.assistantName = weakSelf.assistantName;
            createOrderVc.username = weakSelf.username;
            createOrderVc.courseId = weakSelf.courseId;
            [weakSelf.navigationController pushViewController:createOrderVc animated:YES];
            
        } else {
            [weakSelf.view makeToast:NSLocalizedString(@"PLEASE_SELECT_PERIOD", nil) duration:1.08 position:CSToastPositionCenter];
        }
    };
    
    self.addDay = 0;
    self.baseTool = [[TDBaseToolModel alloc] init];
    [self setviewConstraint];
    
    [self requestNewData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

- (void)joinTimeStr {
    
    NSInteger min = [self sortingArray:0];
    NSInteger max = [self sortingArray:1];
    
    TDTimeModel *minModel = self.timeArray[min];
    TDTimeModel *maxModel = self.timeArray[max];
    
    self.starTimeStr = [self separatTimeStr:minModel.time_slice withType:0];
    self.endTimeStr = [self separatTimeStr:maxModel.time_slice withType:1];
    
    NSLog(@"预约时间 -- %@ ~ %@",self.starTimeStr,self.endTimeStr);
}

#pragma mark - requestData
- (void)requestData {
    
    if (![self.baseTool networkingState]) {
        self.loadingView.hidden = YES;
        return;
    }
    
    self.dateStr = [self dateFormatter:0];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.assistantName forKey:@"username"];
    [dic setValue:self.dateStr forKey:@"plan_date"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/service_plans/%@",ELITEU_URL,self.assistantName];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (self.timeArray.count > 0) {
            [self.timeArray removeAllObjects];
        }
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            NSArray *dataArray = responseDic[@"data"][@"plan_time"];
            if (dataArray.count > 0) {
                for (int i = 0; i < dataArray.count; i ++) {
                    
                    TDTimeModel *model = [TDTimeModel mj_objectWithKeyValues:dataArray[i]];
                    model.canSelected = YES;
                    model.index = i;
                    
                    if (self.timeArray.count == 0) {
                        model.typeNum = 1;
                        self.typeNum = model.typeNum;
                        
                    } else {
                        TDTimeModel *hadModel = self.timeArray[self.timeArray.count - 1];
                        NSString *str1 = [self separatTimeStr:hadModel.time_slice withType:1];
                        NSString *str2 = [self separatTimeStr:model.time_slice withType:0];
                        
                        if ([str1 isEqualToString:str2]) { //前后时间一样，归为一类；不同，归为下一类
                            model.typeNum = self.typeNum;
                        } else {
                            model.typeNum = ++ self.typeNum;
                        }
                        
                        NSLog(@"前后助教时间 -%@-->%@-- %@ == > %@ --- %ld",hadModel.time_slice,model.time_slice,str1,str2,(long)self.typeNum);
                    }
                    if (model) {
                        [self.timeArray addObject:model];
                    }
                }
                
                if (self.timeArray.count > 0) {
                    self.nullLabel.hidden = YES;
                    self.messageLabel.hidden = NO;
                    [self.tableView reloadData];
                } else {
                    self.nullLabel.hidden = NO;
                    self.messageLabel.hidden = YES;
                }
            }
            self.loadingView.hidden = YES;
            
        } else if ([code intValue] == 404) { //该课程暂无助教
            self.nullLabel.hidden = NO;
            self.loadingView.hidden = YES;
            
            self.messageLabel.hidden = YES;
            [self.tableView reloadData];
            [self.view makeToast:NSLocalizedString(@"NO_TA_COURSE_SCHEDULE", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        self.nullLabel.hidden = NO;
        self.loadingView.hidden = YES;
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"时间列表出错 -- %ld",(long)error.code);
    }];
}


#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.timeArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TDTimeModel *model = self.timeArray[indexPath.row];
    TDTeacherTimeCell *cell = [[TDTeacherTimeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDTeacherTimeCell"];
    cell.model = model;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TDTimeModel *selectedModel = self.timeArray[indexPath.row];
    selectedModel.isSelected = !selectedModel.isSelected;
    selectedModel.canSelected = YES;
    
    if (selectedModel.isSelected) { //选中
        if (self.selectArray.count == 0) {
            [self.selectArray addObject:selectedModel];//加入
            [self judgeAllCellCanSelected:indexPath.row]; //可选处理
            
        } else {
            
            NSInteger min = [self sortingArray:0];
            NSInteger max = [self sortingArray:1];
            
            if (abs((selectedModel.index - min) == 1 && selectedModel.index < min) && (labs(selectedModel.index - max) == 1 && selectedModel.index > max)) { //前面连续&&后面连续
                [self.selectArray addObject:selectedModel]; //加入
                
            } else { //不连续
                if (selectedModel.index < min) { //比小的还小
                    for (int i = 0; i < self.timeArray.count; i ++) {
                        TDTimeModel *timeModel = self.timeArray[i];
                        
                        if (timeModel.index >= selectedModel.index && timeModel.index <= max) {
                            timeModel.isSelected = YES;
                            if (![self.selectArray containsObject:timeModel]) {
                                [self.selectArray addObject:timeModel];//加入
                            }
                            
                        } else {
                            timeModel.isSelected = NO;
                        }
                    }
                } else if (selectedModel.index > max) { //比大的还大
                    
                    for (int i = 0; i < self.timeArray.count; i ++) {
                        TDTimeModel *timeModel = self.timeArray[i];
                        if (timeModel.index <= selectedModel.index && timeModel.index >= min) {
                            timeModel.isSelected = YES;
                            if (![self.selectArray containsObject:timeModel]) {
                                [self.selectArray addObject:timeModel];//加入
                            }
                        } else {
                            timeModel.isSelected = NO;
                        }
                    }
                }
            }
        }
        
    } else { //取消选中
        
        NSInteger min = [self sortingArray:0];
        NSInteger max = [self sortingArray:1];
        
        if (labs(selectedModel.index - min) > labs(selectedModel.index - max)) { //小的那边多
            
            for (int i = 0; i < self.timeArray.count; i ++) {
                TDTimeModel *timeModel = self.timeArray[i];
                if (timeModel.index < selectedModel.index && timeModel.index >= min) {
                    timeModel.isSelected = YES;
                } else {
                    timeModel.isSelected = NO;
                    if ([self.selectArray containsObject:timeModel]) {
                        [self.selectArray removeObject:timeModel];
                    }
                }
            }
        } else { //大的那边多
            for (int i = 0; i < self.timeArray.count; i ++) {
                TDTimeModel *timeModel = self.timeArray[i];
                if (timeModel.index > selectedModel.index && timeModel.index <= max) {
                    timeModel.isSelected = YES;
                } else {
                    timeModel.isSelected = NO;
                    if ([self.selectArray containsObject:timeModel]) {
                        [self.selectArray removeObject:timeModel];
                    }
                }
            }
        }
        if (self.selectArray.count == 0) {
            for (int i = 0; i < self.timeArray.count; i ++) {
                TDTimeModel *model = self.timeArray[i];
                model.canSelected = YES;
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark - 数组中最小和最大的index
/*
 0 最小值
 1 最大值
 */
- (NSInteger)sortingArray:(NSInteger)type {
    NSInteger min = 0;
    NSInteger max = 0;
    for (int i = 0; i < self.selectArray.count; i ++) {
        TDTimeModel *model = self.selectArray[i];
        
        if (i == 0) {
            min = model.index;
        } else if (model.index < min) {
            min = model.index;
        }
        
        if (model.index > max) {
            max = model.index;
        }
    }
    
    return type == 0 ? min : max;
}

#pragma mark - 选中的处理
- (void)judgeAllCellCanSelected:(NSInteger)index {
    
    TDTimeModel *selectedModel = self.timeArray[index];
    for (int i = 0; i < self.timeArray.count; i ++) {
        TDTimeModel *model = self.timeArray[i];
        if (model.typeNum == selectedModel.typeNum) {
            model.canSelected = YES;
        } else {
            model.canSelected = NO;
        }
    }
    [self.tableView reloadData];
}

/*
 0 前面的时间
 1 后面的时间
 */
- (NSString *)separatTimeStr:(NSString *)timeStr withType:(NSInteger)type {
    
    NSMutableString *str = [NSMutableString stringWithString:timeStr];
    NSString *str1 = [str substringToIndex:5];
    NSString *str2 = [str substringFromIndex:6];
    NSLog(@" 前 -- %@, 后 -- %@",str1,str2);
    
    if (type == 0) {
        return str1;
    } else {
        return str2;
    }
}

#pragma mark - 按钮
- (void)frontButtonAction:(UIButton *)sender { //左边按钮
    
    self.addDay --;
    [self requestNewTimes];
}

- (void)behindButtonAction:(UIButton *)sender { //右边按钮
    
    self.addDay ++;
    [self requestNewTimes];
}

- (void)requestNewTimes {
    if (self.selectArray.count > 0) {
        [self.selectArray removeAllObjects];
    }
    [self requestNewData];
}

- (void)requestNewData {
    [self judgeButtonEnable];
    self.timesLabel.text = [self dateFormatter:1];
    [self requestData];
}
/*
 type 
 0 : 2017-03-01
 1 : 今天，明天，后天，2017-03-04
 */
- (NSString *)dateFormatter:(NSInteger)type {
    
    NSDate *senddate=[NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitWeekday | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:senddate];

    [components setDay:([components day] + self.addDay)];//今天
    
    NSDate *beginningOfWeek = [gregorian dateFromComponents:components];
    NSDateFormatter *dateday = [[NSDateFormatter alloc] init];
     [dateday setDateFormat:@"yyyy-MM-dd"];
    
    NSString *dateStr = [NSString stringWithFormat:@"%@",[dateday stringFromDate:beginningOfWeek]];
    
    if (type == 1) {
        if (self.addDay == 0) {
            dateStr = NSLocalizedString(@"TODAY", nil);
        } else if (self.addDay == 1) {
            dateStr = NSLocalizedString(@"TOMORROW", nil);
        } else if (self.addDay == 2) {
            dateStr = NSLocalizedString(@"AFTER_TOMOROW", nil);
        }
    }
    
    NSLog(@"dateStr ==  %@",dateStr);
    return dateStr;
}

- (void)judgeButtonEnable {
    
    [self setFrontButtonType:YES];
    [self setbehindButtonType:YES];
    
    if (self.addDay == 0) {
        [self setFrontButtonType:NO];
        
    } else if (self.addDay > 90) {
        [self setbehindButtonType:NO];
    }
}

- (void)setFrontButtonType:(BOOL)isEnable {
    [self.frontButton setImage:[UIImage imageNamed:isEnable == YES ? @"left_blue_image" : @"left_gray_image"] forState:UIControlStateNormal];
    self.frontButton.userInteractionEnabled = isEnable;
}

- (void)setbehindButtonType:(BOOL)isEnable {
    [self.behindButton setImage:[UIImage imageNamed:isEnable == YES ? @"right_blue_image" : @"right_gray_image"] forState:UIControlStateNormal];
    self.behindButton.userInteractionEnabled = isEnable;
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
    
    self.nullLabel = [[UILabel alloc] init];
    self.nullLabel.font = [UIFont fontWithName:@"" size:16];
    self.nullLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.nullLabel.text = NSLocalizedString(@"NO_TA_COURSE_SCHEDULE", nil);
    [self.tableView addSubview:self.nullLabel];
    
    [self.nullLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.tableView.mas_centerX);
        make.centerY.mas_equalTo(self.tableView.mas_centerY).offset(0);
    }];
    
    self.nullLabel.hidden = YES;
    
    self.loadingView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
    [self.view addSubview:self.loadingView];
}

- (UIView *)setTableViewHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 58)];
    
    self.frontButton = [[UIButton alloc] init];
    [self.frontButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    [self.frontButton addTarget:self action:@selector(frontButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.frontButton];
    
    self.behindButton = [[UIButton alloc] init];
    [self.behindButton setImage:[UIImage imageNamed:@"arrow"] forState:UIControlStateNormal];
    [self.behindButton addTarget:self action:@selector(behindButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.behindButton];
    
    self.timesLabel = [[UILabel alloc] init];
    self.timesLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.timesLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.timesLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:self.timesLabel];
    
    [self.frontButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(11);
        make.centerY.mas_equalTo(self.headerView.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(29, 29));
    }];
    
    [self.behindButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.headerView.mas_right).offset(-11);
        make.centerY.mas_equalTo(self.headerView.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(29, 29));
    }];
    
    [self.timesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.frontButton.mas_right).offset(3);
        make.right.mas_equalTo(self.behindButton.mas_left).offset(-3);
        make.centerY.mas_equalTo(self.headerView.mas_centerY);
    }];
    
    [self setFrontButtonType:NO];
    [self setbehindButtonType:YES];
    
    return self.headerView;
}

- (UIView *)settableViewFooterView {
    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, 39)];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.text = NSLocalizedString(@"NOTE_COINS", nil);
    self.messageLabel.numberOfLines = 0;
    [self.footerView addSubview:self.messageLabel];
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.footerView.mas_centerX);
        make.centerY.mas_equalTo(self.footerView.mas_centerY);
    }];
    return self.footerView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end



