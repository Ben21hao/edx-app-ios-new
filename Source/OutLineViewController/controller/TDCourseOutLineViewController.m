//
//  TDCourseOutLineViewController.m
//  edX
//
//  Created by Ben on 2017/6/27.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDCourseOutLineViewController.h"
#import "TDCourseOutLineModel.h"

#import "TDCourseOutLineCell.h"

#import <MJExtension/MJExtension.h>

@interface TDCourseOutLineViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) UILabel *nonDataLabel;

@property (nonatomic,strong) NSMutableArray *dataArray;

@end

@implementation TDCourseOutLineViewController

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
    }
    return _dataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"COURSE_OUTLINE", nil);
    
    [self setViewConstraint];
    [self setLoadDataView];
    [self getOutLineData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - 数据
- (void)getOutLineData {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/courses_outline/%@",ELITEU_URL,self.courseID];
    
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        
        if ([code intValue] == 200) {
            
            NSArray *dataArray = responseDic[@"data"];
            
            if (dataArray.count > 0) {
                for (int i = 0 ; i < dataArray.count; i ++) {
                    NSDictionary *sectionsDic = dataArray[i];
                    TDCourseOutLineModel *model = [TDCourseOutLineModel mj_objectWithKeyValues:sectionsDic];
                    if (model) {
                        model.isOpen = YES;
                        
                        NSArray *sectionsArray = sectionsDic[@"sections"];
                        if (sectionsArray.count > 0) {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            for (int j = 0; j < sectionsArray.count; j ++) {
                                NSDictionary *sectionsDic = sectionsArray[j];
                                TDOutLineSectionsModel *sectionsModel = [TDOutLineSectionsModel mj_objectWithKeyValues:sectionsDic];
                                if (sectionsModel) {
                                    
                                    NSArray *unintsArray = sectionsDic[@"units"];
                                    if (unintsArray.count > 0) {
                                        NSMutableArray *unArray = [[NSMutableArray alloc] init];
                                        for (int k = 0; k < unintsArray.count; k ++) {
                                            TDOutLineUnitsModel *unitsModel = [TDOutLineUnitsModel mj_objectWithKeyValues:unintsArray[k]];
                                            if (unitsModel) {
                                                [unArray addObject:unitsModel];
                                            }
                                        }
                                        sectionsModel.units = unArray;
                                    }
                                    [array addObject:sectionsModel];
                                }
                            }
                            model.sections = array;
                        }
                        [self.dataArray addObject:model];
                    }
                }
            }

        } else {
            
        }
        
        [self.tableView reloadData];
        
        [self.loadIngView removeFromSuperview];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.loadIngView removeFromSuperview];
        NSLog(@"error --%@",error);
    }];
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    self.nonDataLabel.hidden = self.dataArray.count != 0;
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    TDCourseOutLineModel *model = self.dataArray[section];
    if (model.isOpen) {
        return model.sections.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TDCourseOutLineCell *cell = [[TDCourseOutLineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDCourseOutLineCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    TDCourseOutLineModel *model = self.dataArray[indexPath.section];
    NSArray *sectionArray = model.sections;
    if (sectionArray.count > 0) {
        cell.model = sectionArray[indexPath.row];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TDCourseOutLineModel *model = self.dataArray[indexPath.section];
    NSArray *sectionArray = model.sections;
    TDOutLineSectionsModel *sectionModel = sectionArray[indexPath.row];
    if (sectionModel.units.count > 0) {
        return 33 + sectionModel.units.count * 33;
    }
    return 33;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 48;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *view = [self setSectionHeader:section];
    return view;
}

#pragma mark - 分区头
- (UIView *)setSectionHeader:(NSInteger)section {
    
    TDCourseOutLineModel *model = self.dataArray[section];
    NSString *TitleStr = [NSString stringWithFormat:@"%@",model.display_name];
    
    UIView *sectionView = [[UIView alloc] init];
    sectionView.backgroundColor = [UIColor colorWithHexString:colorHexStr6];
    sectionView.layer.borderWidth = 0.5;
    sectionView.layer.borderColor = [UIColor colorWithHexString:colorHexStr7].CGColor;
    
    UIButton *bgButton = [[UIButton alloc] init];
    bgButton.tag = section;
    bgButton.frame = CGRectMake(18, 0, TDWidth , 44);
    [bgButton addTarget:self action:@selector(ClickTitleBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    titleLabel.frame = CGRectMake(18, 0, TDWidth - 48 , 44);
    titleLabel.text = TitleStr;
    titleLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    
    NSString *imageStr = @"Triangle";
    if (model.isOpen) {
        imageStr = @"Triangle_up";
    }
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(TDWidth - 28 , 18, 16, 9)];
    rightButton.userInteractionEnabled = NO;
    [rightButton setImage:[UIImage imageNamed:imageStr] forState:UIControlStateNormal];
    
    [sectionView addSubview:titleLabel];
    [sectionView addSubview:bgButton];
    [sectionView addSubview:rightButton];
    
    return sectionView;
}

#pragma mark - 展开收起
- (void)ClickTitleBtn:(UIButton *)Sender {
    
    NSInteger Int = Sender.tag;
    TDCourseOutLineModel *model = self.dataArray[Int];
    model.isOpen = !model.isOpen;
    
    NSIndexSet *indeSet = [NSIndexSet indexSetWithIndex:Int];
    [self.tableView reloadSections:indeSet withRowAnimation:UITableViewRowAnimationFade];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:Int];
    
    if (model.isOpen && model.sections.count > 0) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - UI
- (void)setViewConstraint {
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];

    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    self.nonDataLabel = [[UILabel alloc] init];
    self.nonDataLabel.font = [UIFont fontWithName:@"OpenSans" size:16];
    self.nonDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.nonDataLabel.hidden = YES;
    self.nonDataLabel.text = NSLocalizedString(@"NO_COURSE_OUTLINE", nil);
    [self.tableView addSubview:self.nonDataLabel];
    
    [self.nonDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.tableView);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
