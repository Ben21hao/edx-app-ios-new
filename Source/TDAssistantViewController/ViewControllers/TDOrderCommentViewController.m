//
//  TDOrderCommentViewController.m
//  edX
//
//  Created by Elite Edu on 17/3/1.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDOrderCommentViewController.h"
#import "TDOrderScoreCell.h"
#import "TDVideoShareCell.h"
#import "TDInputResonCell.h"

#import "TDAssistantCommentTagModel.h"

@interface TDOrderCommentViewController () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSString *reasonStr;
@property (nonatomic,strong) NSMutableArray *selectTagArray;
@property (nonatomic,strong) NSString *scoreStr;

@end

@implementation TDOrderCommentViewController

- (NSArray *)selectTagArray {
    if (!_selectTagArray) {
        _selectTagArray = [[NSMutableArray alloc] init];
    }
    return _selectTagArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"STUDENT_COMMENT", nil);
    [self.rightButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
    WS(weakSelf);
    self.rightButtonHandle = ^{
        [weakSelf handinComment];
    };
    
    [self setViewConstraint];
    
    self.scoreStr = @"5";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

#pragma mark - 提交
- (void)handinComment {
    
    [self.view endEditing:YES];
    
    TDBaseToolModel *toolModel = [[TDBaseToolModel alloc] init];
    if (![toolModel networkingState]) {
        return;
    }
    
    [SVProgressHUD showWithStatus:@"正在提交评价..."];
    SVProgressHUD.defaultMaskType = SVProgressHUDMaskTypeBlack;
    SVProgressHUD.defaultStyle = SVProgressHUDAnimationTypeNative;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:self.assistantId forKey:@"assistant_service_id"];
    [dic setValue:self.scoreStr forKey:@"score"];
    [dic setValue:self.reasonStr forKey:@"content"];
    [dic setValue:@"1" forKey:@"is_allowed_share"];//暂时不做分享，固定传 1
    
    NSString *tagStr = [self.selectTagArray componentsJoinedByString:@","];
    [dic setValue:tagStr forKey:@"tag_ids"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/enterprise/v0.5/assistant/services/comment/",ELITEU_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@" ===== %@",responseObject);
        
        [SVProgressHUD dismiss];
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            if (self.commentSuccessHandle) {
                self.commentSuccessHandle();
            }
            [self.view makeToast:NSLocalizedString(@"COMMENT_SUBMITTED", nil) duration:1.08 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
            
        } else if ([code intValue] == 312) {
            [self.view makeToast:NSLocalizedString(@"HAVE_COMMNET", nil) duration:1.08 position:CSToastPositionCenter];
        } else if ([code intValue] == 500) {
            [self.view makeToast:NSLocalizedString(@"UNABEL_SUBMIT_COMMNET", nil) duration:1.08 position:CSToastPositionCenter];
        } else {
            NSLog(@"提交评论有问题 --- %@",code);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"提交评论出错 --- %ld",(long)error.code);
    }];
}

#pragma mark - tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 0;//暂时不做视频分享
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    WS(weakSelf);
    if (indexPath.section == 0) {
        TDOrderScoreCell *scoreCell = [[TDOrderScoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDOrderScoreCell"];
        scoreCell.selectionStyle = UITableViewCellSelectionStyleNone;
        scoreCell.tagArray = self.tagsArray;
        scoreCell.scoreStr = self.scoreStr;
        
        scoreCell.startButtonHandle = ^(NSInteger tag){
            weakSelf.scoreStr = [NSString stringWithFormat:@"%d",(int)tag + 1];
        };
        scoreCell.tagButtonHandle = ^(NSInteger tag, BOOL isClick){
            TDAssistantCommentTagModel *tagModel = self.tagsArray[tag];
            NSString *tagId = [NSString stringWithFormat:@"%@",tagModel.tag_id];
            tagModel.isSelected = isClick;
            
            if (isClick) {
                [weakSelf.selectTagArray addObject:tagId];
            } else {
                if ([weakSelf.selectTagArray containsObject:tagId]) {
                    [weakSelf.selectTagArray removeObject:tagId];
                }
            }
        };
        return scoreCell;
        
    } else if (indexPath.section == 1) {
        TDVideoShareCell *shareCell = [[TDVideoShareCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDVideoShareCell"];
        shareCell.selectionStyle = UITableViewCellSelectionStyleNone;
        return shareCell;
        
    } else {
        TDInputResonCell *reasonCell = [[TDInputResonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDInputResonCell"];
        reasonCell.selectionStyle = UITableViewCellSelectionStyleNone;
        reasonCell.inputViewResponderHandle = ^(BOOL isResponder){
            [weakSelf.tableView setContentOffset:CGPointMake(0, isResponder ? TDKeybordHeight : 0)];
        };
        reasonCell.inputStrHandle = ^(NSString *reasonStr){
            weakSelf.reasonStr = reasonStr;
        };
        return reasonCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        float row = (float)(self.tagsArray.count - 1) / 3 + 1;
        return 128 + 31 * row;
        
    } else if (indexPath.section == 1) {
        return 55;
        
    } else {
       return 168;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 8;
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
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)tapAction {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
