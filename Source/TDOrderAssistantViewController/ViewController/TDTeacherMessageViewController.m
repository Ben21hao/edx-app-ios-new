//
//  TDTeacherMessageViewController.m
//  edX
//
//  Created by Elite Edu on 17/2/28.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDTeacherMessageViewController.h"
#import "TDBaseTableview.h"

@interface TDTeacherMessageViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,assign) BOOL canScroll;

@end

@implementation TDTeacherMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"HOMEPAGE", nil);
    
    [self setViewConstraint];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptMessage:) name:@"superView_ScrollToTop" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptMessage:) name:@"childView_ScrollLeadTop" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - notification
- (void)acceptMessage:(NSNotification *)notification {
    NSString *notificationName = notification.name;
    
    if ([notificationName isEqualToString:@"superView_ScrollToTop"]) {
        
        self.tableView.showsVerticalScrollIndicator = YES;
        self.canScroll = YES;
        
    } else if ([notificationName isEqualToString:@"childView_ScrollLeadTop"]) {
        
        [self.tableView setContentOffset:CGPointMake(0, 0)];
        self.tableView.showsVerticalScrollIndicator = NO;
        self.canScroll = NO;
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - 滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"下面的 ------ %f ; %f",self.tableView.contentOffset.y,scrollView.contentOffset.y);

    if (self.canScroll == NO) {
        [self.tableView setContentOffset:CGPointMake(0, 0)];
    }
    
    CGFloat offsetY = self.tableView.contentOffset.y;
    if (offsetY < 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"childView_ScrollLeadTop" object:nil];
    }
}

#pragma mark - UI
- (void)setViewConstraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return self.model.introduction.length == 0 ? 0 : 1;
            break;
        case 1:
            return self.model.work_experience.length == 0 ? 0 : 1;
            break;
        case 2:
            return self.model.education_experience.length == 0 ? 0 : 1;
            break;
        case 3:
            return self.model.train_experience.length == 0 ? 0 : 1;
            break;
        case 4:
            return self.model.awards.length == 0 ? 0 : 1;
            break;
        case 5:
            return self.model.skills.length == 0 ? 0 : 1;
            break;
        case 6:
            return self.model.hobbies.length == 0 ? 0 : 1;
            break;
        default:
            break;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"professorCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"professorCell"];
    }
    cell.userInteractionEnabled = NO;
    cell.textLabel.textColor = [UIColor colorWithHexString:colorHexStr9];
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    cell.textLabel.numberOfLines = 0;
    
    switch (indexPath.section) {
        case 0:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"PERSONAL_PROFILE", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.introduction]];
            break;
        case 1:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"WORK_EXPERIENCES", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.work_experience]];
            break;
        case 2:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"EDUCATIONNAL_BACKGROUND", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.education_experience]];
            break;
        case 3:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"TRAINING_EXPERIENCES", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.train_experience]];
            break;
        case 4:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"AWARDS", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.awards]];
            break;
        case 5:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"PROFESSIONAL_SKILLS", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.skills]];
            break;
        case 6:
            cell.textLabel.attributedText = [self setDetailTextAttribute:[NSString stringWithFormat:@"%@\n",NSLocalizedString(@"INTERESTS", nil)] withDetail:[NSString stringWithFormat:@"%@", self.model.hobbies]];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
            
        case 0:
            return [self contentSize:self.model.introduction].height + 48;
            break;
        case 1:
            return [self contentSize:self.model.work_experience].height + 48;
            break;
        case 2:
            return [self contentSize:self.model.education_experience].height + 48;
            break;
        case 3:
            return [self contentSize:self.model.train_experience].height + 48;
            break;
        case 4:
            return [self contentSize:self.model.awards].height + 48;
            break;
        case 5:
            return [self contentSize:self.model.skills].height + 48;
            break;
        case 6:
            return [self contentSize:self.model.hobbies].height + 48;
            break;
    }
    return 48;
}


#pragma mark - 计算文本高度
- (CGSize)contentSize:(NSString *)detailText {
    
    NSMutableParagraphStyle *paragraphStyle = [self setDetailTextPagraph:4.0];
    NSDictionary *attributes = @{
                                 NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],
                                 NSParagraphStyleAttributeName : paragraphStyle
                                 };
    
    //    NSString *str = [detaiText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];//去掉两边空格
    NSString *text = [detailText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];//去掉回车和空格
    
    CGSize contentSize = [text boundingRectWithSize:CGSizeMake(TDWidth - 48, MAXFLOAT)
                                            options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                         attributes:attributes
                                            context:nil].size;
    return contentSize;
}

#pragma mark - 文本attribute
- (NSMutableAttributedString *)setDetailTextAttribute:(NSString *)title withDetail:(NSString *)detail {
    
    NSMutableParagraphStyle *paragraph1 = [self setDetailTextPagraph:8.0];
    NSMutableParagraphStyle *paragraph2 = [self setDetailTextPagraph:4.0];
    
    //    NSString *str = [detail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];//去掉两边空格
    NSString *text = [detail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];//去掉回车和空格
    
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:title
                                                                             attributes:@{
                                                                                          NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:16] ,
                                                                                          NSForegroundColorAttributeName : [UIColor colorWithHexString:@"000000"],
                                                                                          NSParagraphStyleAttributeName : paragraph1
                                                                                          }];
    NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:text
                                                                             attributes:@{
                                                                                          NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14] ,
                                                                                          NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr10],
                                                                                          NSParagraphStyleAttributeName : paragraph2
                                                                                          }];
    [str1 appendAttributedString:str2];
    
    return str1;
}

- (NSMutableParagraphStyle *)setDetailTextPagraph:(float)lineSpace {//段落设置
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc]init] ;
    paragraph.alignment = NSTextAlignmentLeft;
    paragraph.lineSpacing = lineSpace;
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    
    return paragraph;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
