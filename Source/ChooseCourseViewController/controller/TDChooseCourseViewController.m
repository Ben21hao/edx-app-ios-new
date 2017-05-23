//
//  TDChooseCourseViewController.m
//  edX
//
//  Created by Elite Edu on 16/12/10.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDChooseCourseViewController.h"
#import "TDActivityViewController.h"
#import "SubmitCourseViewController.h"
#import "TDSubmitCourseViewController.h"

#import "ActivityListItem.h"//活动
#import "ChooseCourseItem.h"//课程
#import "TDBaseToolModel.h"

#import "TDChooseCourseView.h"
#import "TDChooseCourseCell.h"
#import "TDRecommendCell.h"

#import <MJExtension/MJExtension.h>
#import "edX-Swift.h"

@interface TDChooseCourseViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) TDChooseCourseView *chooseView;

@property (nonatomic,strong) NSMutableArray *activityArray;//活动
@property (nonatomic,strong) NSMutableArray *courseArray;//底部课程
@property (nonatomic,strong) NSMutableArray *topCourseArray;//顶部课程
@property (nonatomic,strong) NSMutableArray *selectCourseArray;//选中课程
@property (nonatomic,strong) NSMutableArray *canUseArray; //能使用的优惠活动

@property (nonatomic,strong) ActivityListItem *activityItem;//适合的活动
@property (nonatomic,strong) NSString *totalMoney;//支付价格
@property (nonatomic,strong) NSString *giftCoin;//赠送宝典

@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) BOOL hideShowPurchase;//是否隐藏内购

@end

@implementation TDChooseCourseViewController

- (TDChooseCourseView *)chooseView {
    if (!_chooseView) {
        _chooseView = [[TDChooseCourseView alloc] init];
        _chooseView.tableView.delegate = self;
        _chooseView.tableView.dataSource = self;
        _chooseView.tableView.tableFooterView = [UIView new];
        _chooseView.totalButton.selected = YES;
        WS(weakSelf);
        _chooseView.totalButtonHandle = ^(BOOL isSelected){
            [weakSelf allSelectButtonAction:isSelected];
        };
        
        _chooseView.summitButtonHandle = ^(){
            [weakSelf submitCoursesButtonAction];
        };
    }
    return _chooseView;
}

- (NSMutableArray *)activityArray {
    if (!_activityArray) {
        _activityArray = [[NSMutableArray alloc] init];
    }
    return _activityArray;
}

- (NSMutableArray *)courseArray {
    if (!_courseArray) {
        _courseArray = [[NSMutableArray alloc] init];
    }
    return _courseArray;
}

- (NSMutableArray *)topCourseArray {
    if (!_topCourseArray) {
        _topCourseArray = [[NSMutableArray alloc] init];
    }
    return _topCourseArray;
}

- (NSMutableArray *)selectCourseArray {
    if (!_selectCourseArray) {
        _selectCourseArray = [[NSMutableArray alloc] init];
    }
    return _selectCourseArray;
}

- (NSMutableArray *)canUseArray {
    if (!_canUseArray) {
        _canUseArray = [[NSMutableArray alloc] init];
    }
    return _canUseArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.activityItem = [[ActivityListItem alloc] init];
    self.baseTool = [[TDBaseToolModel alloc] init];
    
    [self setViewConstraint];
    [self requestData];
    
    [self setLoadDataView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleViewLabel.text = NSLocalizedString(@"COURSE_LIST", nil);
    
    if (self.whereFrom == TDChooseCourseFromFree) {
        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        }
    }
}

- (void)backButtonAction:(UIButton *)sender {
    
    if (self.whereFrom == TDChooseCourseFromBuy) {
        [self.navigationController popViewControllerAnimated:YES];
        
    } else if (self.whereFrom == TDChooseCourseFromFree) {
        [self.navigationController popToViewController:self.navigationController.childViewControllers[1] animated:YES];
    }
}


#pragma mark - 数据
- (void)requestData {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:self.username forKey:@"username"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/load_all_valid_courses/",ELITEU_URL];
    
    [manager GET:url parameters:dict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responDic = (NSDictionary *)responseObject;
        id code = responDic[@"code"];
        if ([code intValue] == 200) {
            NSDictionary *dataDic = responDic[@"data"];
            
            NSArray *activityArray = dataDic[@"activity_list"];//优惠活动
            if (activityArray.count > 0) {
                for (int i = 0; i < activityArray.count; i ++) {
                    ActivityListItem *model = [ActivityListItem mj_objectWithKeyValues:activityArray[i]];
                    if (model) {
                        [self.activityArray addObject:model];
                    }
                }
            }
            
            NSArray *courseArray = dataDic[@"course_list"]; //课程
            if (courseArray.count > 0) {
                for (int j = 0; j < courseArray.count; j ++) {
                    ChooseCourseItem *item = [ChooseCourseItem mj_objectWithKeyValues:courseArray[j]];
                    if (item) {
                        if ([item.course_id isEqualToString:self.courseID]) {
                            item.isSelected = YES;
                            [self.topCourseArray addObject:item];
                            [self.selectCourseArray addObject:item];
                            
                        } else {
                            [self.courseArray addObject:item];
                        }
                    }
                }
            }
            
            [self setMoneyMessage];
            
            //是否隐藏内购；
            WS(weakSelf);
            self.baseTool.judHidePurchseHandle = ^(BOOL isHidePurchase){
                weakSelf.hideShowPurchase = isHidePurchase;
                [weakSelf.chooseView.tableView reloadData];
                
                if (weakSelf.hideShowPurchase) {
                    [weakSelf judgeFitActivity];
                }
            };
            [self.baseTool showPurchase];
 
        } else {
            NSLog(@"----%@----",responDic[@"msg"]);
        }
        
        [self.loadIngView removeFromSuperview];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadIngView removeFromSuperview];
        NSLog(@"error--%@",error);
    }];

}

#pragma mark - 全选
- (void)allSelectButtonAction:(BOOL)isSelected {
    
    [self.selectCourseArray removeAllObjects];//不方便对比，全部清除

    for (int i = 0; i < self.topCourseArray.count; i ++) {
        ChooseCourseItem *item = self.topCourseArray[i];
        item.isSelected = isSelected;
        
        if (isSelected) {//选中之后才加入
            [self.selectCourseArray addObject:item];
        }
    }
    [self setMoneyMessage];
    if (self.hideShowPurchase) {
        [self judgeFitActivity];
    }
    [self.chooseView.tableView reloadData];
}

#pragma mark - 活动页
- (void)gotoActivityView {
    
    TDActivityViewController *activityVC = [[TDActivityViewController alloc] init];
    activityVC.dataArray = self.activityArray;
    activityVC.courseArray = self.selectCourseArray;
    activityVC.activityStr = self.activityItem.activity_name;
    
    float totalMoney = 0;
    for (int i = 0; i < self.selectCourseArray.count; i ++) {
        ChooseCourseItem *courseIrem = self.selectCourseArray[i];
        totalMoney += [courseIrem.min_price floatValue];
    }
    activityVC.totalMoney = [NSString stringWithFormat:@"%.2lf",totalMoney];//
    
    WS(weakSelf);
    activityVC.selectActivityHandle = ^(ActivityListItem *model){
        weakSelf.activityItem = model;
        [weakSelf setMoneyMessage];
        [weakSelf caculateDiscountActivity]; //计算折扣
        [weakSelf.chooseView.tableView reloadData];
    };
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:activityVC animated:YES];
}

#pragma mark - 提交课表
- (void)submitCoursesButtonAction {//提交课表

    if (![self judgeHasCourseSelect]) {
        [self.view makeToast:@"请选择课程" duration:1.08 position:CSToastPositionCenter];
        return;
    }
    TDSubmitCourseViewController *submitVC = [[TDSubmitCourseViewController alloc] init];
    submitVC.totalM = [self.totalMoney floatValue];//总价格
    submitVC.username = self.username;
    submitVC.activity_id = self.activityItem.activity_id;//活动id
    submitVC.array0 = self.selectCourseArray;
    submitVC.hideShowPurchase = self.hideShowPurchase;
    if ([self.giftCoin floatValue] > 0) {
        submitVC.giftCoin = self.giftCoin;
    }
    
    [self.navigationItem setTitle:@""];
    [self.navigationController pushViewController:submitVC animated:YES];
}

- (BOOL)judgeHasCourseSelect {//至少选择一门课程
    
    if (self.topCourseArray.count > 0) {
        for (ChooseCourseItem *courseIrem in self.topCourseArray) {
            if (courseIrem.isSelected == YES) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)judgeAllSelectCourse {//判断是否全选
    if (self.selectCourseArray.count == self.topCourseArray.count) {
        self.chooseView.totalButton.selected = YES;
        
    } else if (self.selectCourseArray.count < self.topCourseArray.count) {
        self.chooseView.totalButton.selected = NO;
    }
}

- (void)setMoneyMessage {//计算钱数量
    
    float totalMoney = 0;
    float originMoney = 0;
    float giftMoney = 0;
    for (int i = 0; i < self.selectCourseArray.count; i ++) {
        ChooseCourseItem *courseIrem = self.selectCourseArray[i];
        totalMoney += [courseIrem.min_price floatValue];
        originMoney += [courseIrem.suggest_price floatValue];
        giftMoney += [courseIrem.give_coin floatValue];
    }
    
    self.totalMoney = [NSString stringWithFormat:@"%.2lf",totalMoney];//
    self.chooseView.totalMoney.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%@",self.totalMoney] withFont:14  type:1];
    self.chooseView.originalMoney.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%.2f",originMoney] withFont:13  type:2];

    if (giftMoney > 0) { //有赠送宝典的时候再显示
        self.giftCoin = [NSString stringWithFormat:@"%.2f",giftMoney];
        NSString *coinNumStr = [Strings giveCoinsNumberWithCount:self.giftCoin];
        NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"HANDIN_COURSE_LIST", nil)] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14]}];
        NSMutableAttributedString *str2 = [self.baseTool setDetailString:coinNumStr withFont:11 withColorStr:colorHexStr3];
        [str1 appendAttributedString:str2];
        [self.chooseView.summitButton setAttributedTitle:str1 forState:UIControlStateNormal];
        
    } else {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"HANDIN_COURSE_LIST", nil) attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14]}];
        [self.chooseView.summitButton setAttributedTitle:str forState:UIControlStateNormal];
    }
}

#pragma mark - 没选择折扣的情况下，自动判断最低价格
- (void)judgeFitActivity { //判断适合哪种优惠，且计算得到最低的价格
    
    if (self.selectCourseArray.count == 0) {
        self.activityItem = [[ActivityListItem alloc] init];
        [self.chooseView.tableView reloadData];
        return;
    }
    if (self.activityArray.count == 0) {
        return;
    }
    if (self.canUseArray.count != 0) {
        [self.canUseArray removeAllObjects];
    }
    float totalMoney = [self.totalMoney floatValue];
    NSMutableArray *fitArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.activityArray.count; i ++) {
        ActivityListItem *activityItem = self.activityArray[i];
        
        float reduceMoney = 0.0;
    
        NSString *activityInfo = activityItem.other_info;
        NSArray *infoArr = [activityInfo componentsSeparatedByString:@"|"];
        if (infoArr.count == 2) {
            
            NSString *condition = infoArr[0];
            NSString *activity = infoArr[1];
            
            int activityType = [activityItem.activity_type intValue];
            if (activityType == 3) {//满减
                
                if (totalMoney >= [condition floatValue]) {
                    reduceMoney = totalMoney - [activity floatValue];
                    [self.canUseArray addObject:activityItem];
                }
            } else if (activityType == 4) {//满折
                
                if (totalMoney >= [condition floatValue]) {
                    reduceMoney = totalMoney * [activity floatValue];
                    [self.canUseArray addObject:activityItem];
                }
            } else if (activityType == 5) {//买几门减几门价格
                if (self.selectCourseArray.count >= [condition intValue]) {
                    
                    NSArray *courseIdArr = [activity componentsSeparatedByString:@","];
                    if (courseIdArr.count > 0) {
                        
                        NSMutableArray *accordArr = [[NSMutableArray alloc] init];
                        for (ChooseCourseItem *courseItem in self.selectCourseArray) {
                            if ([courseIdArr containsObject:courseItem.course_id]) {
                                [accordArr addObject:courseItem.min_price];
                            }
                        }
                        
                        if (accordArr.count >= [condition intValue]) {
                            NSArray *result = [accordArr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                                NSLog(@"%@++++++++%@",obj1,obj2);
                               NSNumber *num1 = [NSNumber numberWithInt:[obj1 intValue]];
                                NSNumber *num2 = [NSNumber numberWithInt:[obj2 intValue]];
                                return [num1 compare:num2];
                            }];
                            NSLog(@"升序 ------ %@",result);
                            reduceMoney = totalMoney - [result[0] floatValue];
                            [self.canUseArray addObject:activityItem];
                        }
                    }
                }
            }
        }
        if (reduceMoney > 0.0) {
            [fitArray addObject:[NSDictionary dictionaryWithObject:activityItem.activity_id forKey:[NSNumber numberWithFloat:reduceMoney]]];
        }
    }
    
    NSArray *resultArray = [fitArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        NSNumber *number1 = [[obj1 allKeys] objectAtIndex:0];
        NSNumber *number2 = [[obj2 allKeys] objectAtIndex:0];
        
        NSComparisonResult result = [number1 compare:number2];
        return result == NSOrderedDescending; // 升序
    }];
    
    NSLog(@"+++升序+++ %@ ++++++++",resultArray);
    if (resultArray.count > 0) {
        
        NSDictionary *fitDic = resultArray[0];
        NSLog(@"++++----%@",fitDic);
        float min_price =  [[fitDic allKeys].firstObject floatValue];
        
        for (ActivityListItem *activityItem in self.activityArray) {
            if ([activityItem.activity_id isEqualToString:[fitDic allValues].firstObject]) {
                self.activityItem = activityItem;
            }
        }
        self.totalMoney = [NSString stringWithFormat:@"%.2lf",min_price];
        self.chooseView.totalMoney.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%@",self.totalMoney] withFont:14  type:1];
    } else {
        self.activityItem = [[ActivityListItem alloc] init];
    }
    [self.chooseView.tableView reloadData];
}

#pragma mark - 计算选择的折扣
- (void)caculateDiscountActivity {
    
    float totalMoney = [self.totalMoney floatValue];
    float reduceMoney = totalMoney;
    
    if ([self.activityItem.activity_name isEqualToString:NSLocalizedString(@"SELECT_ACTIVITY_ITEM", nil)]) {
        
        self.totalMoney = [NSString stringWithFormat:@"%.2lf",reduceMoney];
        self.chooseView.totalMoney.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%@",self.totalMoney] withFont:14 type:1];
        return;
    }
    
    NSString *activityInfo = self.activityItem.other_info;
    NSArray *infoArr = [activityInfo componentsSeparatedByString:@"|"];
    if (infoArr.count == 2) {
        
        NSString *condition = infoArr[0];
        NSString *activity = infoArr[1];
        int activityType = [self.activityItem.activity_type intValue];
        if (activityType == 3) {//满减
            
            if (totalMoney >= [condition floatValue]) {
                reduceMoney = totalMoney - [activity floatValue];
            }
        } else if (activityType == 4) {//满折
            
            if (totalMoney >= [condition floatValue]) {
                reduceMoney = totalMoney * [activity floatValue];
            }
        } else if (activityType == 5) {//买几门减几门价格
            if (self.selectCourseArray.count >= [condition intValue]) {
                
                NSArray *courseIdArr = [activity componentsSeparatedByString:@","];
                if (courseIdArr.count > 0) {
                    
                    NSMutableArray *accordArr = [[NSMutableArray alloc] init];
                    for (ChooseCourseItem *courseItem in self.selectCourseArray) {
                        if ([courseIdArr containsObject:courseItem.course_id]) {
                            [accordArr addObject:courseItem.min_price];
                        }
                    }
                    
                    if (accordArr.count >= [condition intValue]) {
                        NSArray *result = [accordArr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                            NSNumber *num1 = [NSNumber numberWithInt:[obj1 intValue]];
                            NSNumber *num2 = [NSNumber numberWithInt:[obj2 intValue]];
                            return [num1 compare:num2];
                        }];
                        NSLog(@"升序 ------ %@",result);
                        reduceMoney = totalMoney - [result[0] floatValue];
                    }
                }
            }
        }
        
        self.totalMoney = [NSString stringWithFormat:@"%.2lf",reduceMoney];
        self.chooseView.totalMoney.attributedText = [self.baseTool setString:[NSString stringWithFormat:@"￥%@",self.totalMoney] withFont:14 type:1];
    }
}

#pragma mark - 判断哪些优惠券是可用的
//- (void)judgeCanUseActivity {
//    
//    float totalMoney = [self.totalMoney floatValue];
//    
//    for (int i = 0; i < self.activityArray.count; i ++) {
//        ActivityListItem *activityItem = self.activityArray[i];
//        
//        NSString *activityInfo = activityItem.other_info;
//        NSArray *infoArr = [activityInfo componentsSeparatedByString:@"|"];
//        if (infoArr.count == 2) {
//            
//            NSString *condition = infoArr[0];
//            NSString *activity = infoArr[1];
//            int activityType = [activityItem.activity_type intValue];
//            if (activityType == 3) {//满减
//                if (totalMoney >= [condition floatValue]) {
//                    activityItem.canUse = YES;
//                } else{
//                    activityItem.canUse = NO;
//                }
//                
//            } else if (activityType == 4) {//满折
//                if (totalMoney >= [condition floatValue]) {
//                    activityItem.canUse = YES;
//                } else{
//                    activityItem.canUse = NO;
//                }
//                
//            } else if (activityType == 5) {//买几门减几门价格
//                if (self.activityArray.count >= [condition intValue]) {
//                    
//                    NSArray *courseIdArr = [activity componentsSeparatedByString:@","];
//                    if (courseIdArr.count > 0) {
//                        
//                        NSMutableArray *accordArr = [[NSMutableArray alloc] init];
//                        for (ChooseCourseItem *courseItem in self.courseArray) {
//                            if ([courseIdArr containsObject:courseItem.course_id]) {
//                                [accordArr addObject:courseItem.min_price];
//                            }
//                        }
//                        
//                        if (accordArr.count >= [condition intValue]) {
//                            activityItem.canUse = YES;
//                        } else {
//                            activityItem.canUse = NO;
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    [self.chooseView.tableView reloadData];
//}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.topCourseArray.count;
    } else if (section == 1) {
        return self.hideShowPurchase ? 1 : 0;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorColor = [UIColor colorWithHexString:colorHexStr6];
    tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    WS(weakSelf);
    if (indexPath.section == 0) {
        ChooseCourseItem *model = self.topCourseArray[indexPath.row];
        
        TDChooseCourseCell *cell = [[TDChooseCourseCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDChooseCourseCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell setDataModel:model];
        
        cell.selectButtonHandle = ^(BOOL isSelected){
            model.isSelected = isSelected;
            if (isSelected == YES) {
                [self.selectCourseArray addObject:model];
            } else {
                [self.selectCourseArray removeObject:model];
            }
            [weakSelf judgeAllSelectCourse];//判断是否全选
            [weakSelf setMoneyMessage];
            if (weakSelf.hideShowPurchase) {
                [weakSelf judgeFitActivity];
            }
        };
        return cell;
        
    } else if (indexPath.section == 1) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDActivityCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"TDActivityCell"];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
        cell.detailTextLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
        
        cell.textLabel.text = NSLocalizedString(@"CHOOSE_ACTIVITY", nil);
        if (self.canUseArray.count > 0) {
            cell.detailTextLabel.text = self.activityItem.activity_name.length > 0 ? self.activityItem.activity_name : NSLocalizedString(@"SELECT_ACTIVITY_ITEM", nil);
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"NO_ACTIVITY", nil);
        }
        
        return cell;
        
    } else {
        TDRecommendCell *cell = [[TDRecommendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDRecommendCourseCell"];
        [cell setDataWithDataArray:self.courseArray];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.selectCourseHandle = ^(NSInteger index){
            
            ChooseCourseItem *model = self.courseArray[index];
            model.isSelected = YES;
            
            [self.topCourseArray addObject:model];
            [self.selectCourseArray addObject:model];
            [self.courseArray removeObject:model];
            
            [weakSelf.chooseView.tableView reloadData];
            
            [weakSelf judgeAllSelectCourse];
            [weakSelf setMoneyMessage];
            if (weakSelf.hideShowPurchase) {
                [weakSelf judgeFitActivity];//判断适合的折扣
            }
            
        };
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self gotoActivityView];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return 120;
    } else if (indexPath.section == 2) {
        if (self.courseArray.count > 0) {
            NSInteger row = (self.courseArray.count - 1) / 2;
            return (row + 1) * ((TDWidth - 30) / 2);
        } else {
            return 0;
        }
    } else {
       return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 2) {
        return self.courseArray.count > 0 ? 48 : 0;
    } else {
        return 0;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (section == 2) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
        
        UILabel *title = [[UILabel alloc] init];
        title.text = NSLocalizedString(@"RECOMMEND_COURSE", nil);
        title.font = [UIFont fontWithName:@"OpenSans" size:14];
        title.textAlignment = NSTextAlignmentCenter;
        title.textColor = [UIColor colorWithHexString:colorHexStr8];
        [view addSubview:title];
        [title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.mas_equalTo(view.mas_centerX);
            make.centerY.mas_equalTo(view.mas_centerY);
        }];
        
        UILabel *line1 = [[UILabel alloc] init];
        line1.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [view addSubview:line1];
        [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(view.mas_centerY);
            make.left.mas_equalTo(view.mas_left);
            make.right.mas_equalTo(title.mas_left).offset(-8);
            make.height.mas_equalTo(1);
        }];
        
        UILabel *line2 = [[UILabel alloc] init];
        line2.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
        [view addSubview:line2];
        [line2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(view.mas_centerY);
            make.left.mas_equalTo(title.mas_right).offset(8);
            make.right.mas_equalTo(view.mas_right);
            make.height.mas_equalTo(1);
        }];
        
//        UIImageView *imgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GroupT"]];
//        [view addSubview:imgV];
//        [imgV mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.centerY.mas_equalTo(view.mas_centerY);
//            make.centerX.mas_equalTo(view.mas_centerX);
//        }];
        return view;
        
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        return view;
    }
}

#pragma mark - 删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return indexPath.section == 0 ? YES : NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChooseCourseItem *model = self.topCourseArray[indexPath.row];
    model.isSelected = NO;
    [self.topCourseArray removeObject:model];
    [self.selectCourseArray removeObject:model];
    [self.courseArray addObject:model];
    
    [self.chooseView.tableView reloadData];
    [self judgeAllSelectCourse];
    [self setMoneyMessage];
    if (self.hideShowPurchase) {
        [self judgeFitActivity];
    }
}

#pragma makr - UI
- (void)setViewConstraint {
    [self.view addSubview:self.chooseView];
    [self.chooseView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(self.view);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
@end
