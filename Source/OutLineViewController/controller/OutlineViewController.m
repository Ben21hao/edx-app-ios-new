//
//  OutlineViewController.m
//  edX
//
//  Created by Elite Edu on 16/9/27.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "OutlineViewController.h"
#import <AFNetworking.h>
#import "UIColor+JHHexColor.h"
#import <MJExtension/MJExtension.h>

#import "OutlineFirstItem.h"
#import "OutlineSecondItem.h"
#import "OutlineThirdItem.h"
#import "TDOutLineCell.h"

#define TDWidth [UIScreen mainScreen].bounds.size.width
#define TDHeight [UIScreen mainScreen].bounds.size.height
static BOOL isBOOL[100];
@interface OutlineViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *dataArr;//总组数

@end

@implementation OutlineViewController

static NSString *ID = @"outline";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"COURSE_OUTLINE", nil);
    
    [self getDate];
    
    //注册cell
    [self addTableView];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"OutLineTableViewCell" bundle:nil] forCellReuseIdentifier:ID];
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    _dataArr = [NSMutableArray array];
    
    [self setLoadDataView];
}
- (void)addTableView{
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tag = 10;
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
}

#pragma mark - data
- (void)getDate{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/courses/v1/courses_outline/%@",ELITEU_URL,self.courseID];
    
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSArray *arr = (NSArray *)responseObject[@"data"];
        [_dataArr addObjectsFromArray:arr];
        
        for (int i = 0; i < self.dataArr.count; i++) {
            isBOOL[i] = YES;
        }
        
        [self.tableView reloadData];
        
        [self.loadIngView removeFromSuperview];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        [self.loadIngView removeFromSuperview];
        NSLog(@"error --%@",error);
    }];

}

#pragma mark -- UITableViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView.tag==10){
        return _dataArr.count;
    }else{
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView.tag==10){
        if (isBOOL[section]){
            OutlineFirstItem *item1 = [OutlineFirstItem mj_objectWithKeyValues:_dataArr[section]];
            return item1.sections.count;
        }else{
            return 0;
        }
    }else{
        return 0;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag==10){
        
        TDOutLineCell *Cell = [[TDOutLineCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OutLineCell"];
        Cell.userInteractionEnabled = NO;
        OutlineFirstItem *item1 = [OutlineFirstItem mj_objectWithKeyValues:_dataArr[indexPath.section]];
        
        NSArray *subArr = item1.sections;
        OutlineSecondItem *item2 = [OutlineSecondItem mj_objectWithKeyValues:subArr[indexPath.row]];
        Cell.titleLabel.text = item2.display_name;
        if (item2.units.count > 0) {
            [Cell setDataForOutLine:item2.units];
        }
        
        return Cell;
    }else{
        static NSString * Str =@"Cell";
        UITableViewCell * Cell = [tableView dequeueReusableCellWithIdentifier:Str];
        if (Cell==nil){
            Cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Str];
        }
        Cell.textLabel.text = @"222";
        return Cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OutlineFirstItem *item1 = [OutlineFirstItem mj_objectWithKeyValues:_dataArr[indexPath.section]];
    NSArray *subArr = item1.sections;
    OutlineSecondItem *item2 = [OutlineSecondItem mj_objectWithKeyValues:subArr[indexPath.row]];
    if (item2.units.count > 0) {
        return 33 + item2.units.count * 33;
    }
    return 33;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView.tag==10){
        return 48;
    }else{
        return 0;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *view = [self setSectionHeader:section];
    return view;
}

#pragma mark - 分区头
- (UIView *)setSectionHeader:(NSInteger)section {
    
    OutlineFirstItem *item1 = [OutlineFirstItem mj_objectWithKeyValues:_dataArr[section]];
    NSString *TitleStr = [NSString stringWithFormat:@"%@",item1.display_name];
    
    UIView *sectionView = [[UIView alloc] init];
    sectionView.backgroundColor = [UIColor colorWithHexString:@"#E6E9ED"];
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
    if (isBOOL[section]) {
        imageStr = @"Triangle_up";
    }
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(TDWidth - 28 , 18, 16, 9)];
    rightButton.userInteractionEnabled = NO;
//    [rightButton addTarget:self action:@selector(ClickTitleBtn:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setImage:[UIImage imageNamed:imageStr] forState:UIControlStateNormal];
    
    [sectionView addSubview:titleLabel];
    [sectionView addSubview:bgButton];
    [sectionView addSubview:rightButton];
    
    return sectionView;
}


#pragma mark - 展开收起
- (void)ClickTitleBtn:(UIButton *)Sender{
    
    NSInteger Int = Sender.tag;
    isBOOL[Int]= !isBOOL[Int];
    
    NSIndexSet * indeSet = [NSIndexSet indexSetWithIndex:Int];
    UITableView * table = (UITableView *)[self.view viewWithTag:10];
    [table reloadSections:indeSet withRowAnimation:UITableViewRowAnimationFade];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:Int];
    
    OutlineFirstItem *item1 = [OutlineFirstItem mj_objectWithKeyValues:_dataArr[Int]];
    NSArray *subArr = item1.sections;
    
    if (isBOOL[Int] && subArr.count > 0) {
        [table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
