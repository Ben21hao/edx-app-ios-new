//
//  TDInformationDetailViewController.m
//  edX
//
//  Created by Ben on 2017/4/26.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDInformationDetailViewController.h"
#import "TDTakePictureViewController.h"

#import "TDInformationDetailView.h"
#import "TDBaseView.h"

#import "TDBaseToolModel.h"
#import <UIImageView+WebCache.h>


typedef NS_ENUM(NSInteger,TDMessageShow) {
    TDMessageShowProgress = 1,
    TDMessageShowFailed
};

@interface TDInformationDetailViewController () <UIGestureRecognizerDelegate>

@property (nonatomic,strong) TDInformationDetailView *messageView;
@property (nonatomic,strong) UIView *headerView;

@property (nonatomic,strong) UILabel *topLabel;
@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UIButton *resetButton;
@property (nonatomic,strong) UIImageView *leftImage;
@property (nonatomic,strong) UIImageView *rightImage;

@property (nonatomic,strong) NSString *status;
@property (nonatomic,strong) NSString *messageStr;

@property (nonatomic,strong) UIView *bigView;
@property (nonatomic,strong) UIImageView *bigImage;

@property (nonatomic,strong) TDBaseView *loadIngView;

@end

@implementation TDInformationDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"AUTHENTICATION_MESSAGE", nil);
    [self requestData];
    
    self.loadIngView = [[TDBaseView alloc] initWithLoadingFrame:self.view.bounds];
    [self.view addSubview:self.loadIngView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
    [backButton setImage:[UIImage imageNamed:@"backImagee"] forState:UIControlStateNormal];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && self.whereFrom == TDAuthenMessageFromFinish) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

#pragma mark - 返回
- (void)backButtonAction:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - requestData
- (void)requestData {
    
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    if (![baseTool networkingState]) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil) duration:0.8 position:CSToastPositionCenter];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
        return;
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic  setValue:self.username forKey:@"username"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/users/authentication/get_authent_message/",ELITEU_URL];
    
    [manager GET:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200) {
            NSDictionary *dataDic = responseDic[@"data"];
            
            self.status = [NSString stringWithFormat:@"%@",dataDic[@"status"]]; //200 提交成功 201 认证成功 202 认证失败
            self.messageStr = [NSString stringWithFormat:@"%@",dataDic[@"error_msg"]];
            [self remarkView:[self.status intValue] == 202 ? TDMessageShowFailed : TDMessageShowProgress];
            
            self.messageView.name = [NSString stringWithFormat:@"%@",dataDic[@"name"]];
            self.messageView.identifyID = [NSString stringWithFormat:@"%@",dataDic[@"identityid"]];
            self.messageView.birthDate = [NSString stringWithFormat:@"%@",dataDic[@"birthdate"]];
            self.messageView.sexStr = [dataDic[@"gender"] isEqualToString:@"m"] ? NSLocalizedString(@"TD_MAN", nil) : NSLocalizedString(@"TD_WOMEN", nil);
            
            NSString *faceStr = [NSString stringWithFormat:@"%@%@",ELITEU_URL,dataDic[@"face_image"]];
            NSString *identifyStr = [NSString stringWithFormat:@"%@%@",ELITEU_URL,dataDic[@"identity_image"]];
            
            [self.leftImage sd_setImageWithURL:[NSURL URLWithString:faceStr] placeholderImage:[UIImage imageNamed:@"tdFaceImage"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
            [self.rightImage sd_setImageWithURL:[NSURL URLWithString:identifyStr] placeholderImage:[UIImage imageNamed:@"tdIdentify"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            }];
            [self.messageView.tableView reloadData];
            
        } else {
            [self.view makeToast:NSLocalizedString(@"FAILED_QUESTE", nil) duration:0.8 position:CSToastPositionCenter];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popToRootViewControllerAnimated:YES];
            });
        }
        
        [self.loadIngView removeFromSuperview];
        NSLog(@"msg ---- %@ \n responseDic ==== %@",responseDic[@"msg"],responseDic);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        [self.loadIngView removeFromSuperview];
        NSLog(@"%ld",(long)error.code);
    }];
}

#pragma mark - 重新审核
- (void)resetButtonAction:(UIButton *)sender {
    
    TDTakePictureViewController *photoVC = [[TDTakePictureViewController alloc] init];
    photoVC.whereFrom = TDAuthenFromProfile;
    photoVC.username = self.username;
    [self.navigationController pushViewController:photoVC animated:YES];
}

#pragma mark - 点击相片
- (void)tap1Action:(UITapGestureRecognizer *)sender {
    [self showImageBigView:self.leftImage.image];
}

- (void)tap2Action:(UITapGestureRecognizer *)sender {
    [self showImageBigView:self.rightImage.image];
}

- (void)tap3Action:(UITapGestureRecognizer *)sender {
    
    [UIView animateWithDuration:0.5 animations:^{
        self.bigView.frame = CGRectMake(0, 0, 0, 0);
        self.bigImage.frame = CGRectMake(0, 0, 0, 0);
    } completion:^(BOOL finished) {
        self.bigView.alpha = 0;
        self.bigView.hidden = YES;
    }];
}

- (void)showImageBigView:(UIImage *)image {
    
    self.bigView.hidden = NO;
    self.bigImage.image = image;
    [UIView animateWithDuration:0.5 animations:^{
        self.bigView.alpha = 1;
        self.bigView.frame = CGRectMake(0, 0, TDWidth, TDHeight);
        self.bigImage.frame = CGRectMake(0, (TDHeight - TDWidth - 60) / 2, TDWidth, TDWidth);
    }];
}

- (void)setImageBigView { //大图显示
    
    self.bigView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.bigView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bigView];
    
    self.bigImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.bigView addSubview:self.bigImage];
    
    self.bigView.hidden = YES;
    self.bigView.alpha = 0;
    
    self.bigView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap3Action:)];
    [self.bigView addGestureRecognizer:tap3];
}

#pragma mark - remark UI
- (void)remarkView:(NSInteger)type {
    
    [self configView:type];
    [self setViewConstraint:type];
    [self setImageBigView];
}

#pragma mark - UI
- (void)configView:(NSInteger)type {
    
    self.messageView = [[TDInformationDetailView alloc] init];
    [self.view addSubview:self.messageView];
    
    float width = (TDWidth - 48) / 2;
    float height = 108 + width;
    if (type == TDMessageShowFailed) {
        if (self.messageStr.length > 0) {
            CGSize size = [self.messageStr boundingRectWithSize:CGSizeMake(TDWidth - 36, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14]} context:nil].size;
            height = 118 + width + size.height;
        } else {
            height = 118 + width;
        }
    }
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, height)];
    [self.view addSubview:self.headerView];
    
    self.messageView.tableView.tableHeaderView = self.headerView;
    
    self.topLabel = [[UILabel alloc] init];
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:18];
    self.topLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.topLabel.textAlignment = NSTextAlignmentCenter;
    self.topLabel.text = type == TDMessageShowProgress ? NSLocalizedString(@"HANDIN_SUCCESS", nil) : NSLocalizedString(@"AUTHEN_NO_PASS", nil);
    [self.headerView addSubview:self.topLabel];
    
    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.messageLabel.textColor = [UIColor colorWithHexString:colorHexStr10];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = type == TDMessageShowProgress ? NSLocalizedString(@"WAIT_FOR_RESULT", nil) : self.messageStr;;
    [self.headerView addSubview:self.messageLabel];
    
    self.resetButton = [[UIButton alloc] init];
    self.resetButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    [self.resetButton setTitle: NSLocalizedString(@"AUTHENT_AGAIN", nil) forState:UIControlStateNormal];
    [self.resetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.resetButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.resetButton.layer.cornerRadius = 4.0;
    [self.resetButton addTarget:self action:@selector(resetButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.resetButton];
    
    self.resetButton.hidden = type == TDMessageShowProgress ? YES : NO;
    
    self.leftImage = [self setImageType];
    [self.headerView addSubview:self.leftImage];
    
    self.rightImage = [self setImageType];
    [self.headerView addSubview:self.rightImage];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap1Action:)];
    self.leftImage.userInteractionEnabled = YES;
    [self.leftImage addGestureRecognizer:tap1];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap2Action:)];
    self.rightImage.userInteractionEnabled = YES;
    [self.rightImage addGestureRecognizer:tap2];
}

- (void)setViewConstraint:(NSInteger)type {
    
    [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(8);
        make.right.mas_equalTo(self.headerView.mas_right).offset(-8);
        make.top.mas_equalTo(self.headerView.mas_top).offset(18);
        
    }];
    
    [self.messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(18);
        make.right.mas_equalTo(self.headerView.mas_right).offset(-18);
        make.top.mas_equalTo(self.topLabel.mas_bottom).offset(8);
        if (self.messageLabel.text.length == 0 && type == TDMessageShowFailed) {
            make.top.mas_equalTo(self.topLabel.mas_bottom).offset(0);
        }
    }];
    
    [self.resetButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(type == TDMessageShowProgress ? 0 : 8);
        make.left.mas_equalTo(self.headerView.mas_left).offset(28);
        make.right.mas_equalTo(self.headerView.mas_right).offset(-28);
        make.height.mas_equalTo(type == TDMessageShowProgress ? 0 : 39);
    }];
    
    float width = (TDWidth - 48) / 2;
    [self.leftImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.headerView.mas_left).offset(18);
        make.top.mas_equalTo(self.resetButton.mas_bottom).offset(11);
        make.size.mas_equalTo(CGSizeMake(width, width));
        
    }];
    
    [self.rightImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.headerView.mas_right).offset(-18);
        make.top.mas_equalTo(self.resetButton.mas_bottom).offset(11);
        make.size.mas_equalTo(CGSizeMake(width, width));
    }];
}

- (UIImageView *)setImageType {
    UIImageView *image = [[UIImageView alloc] init];
    image.backgroundColor = [UIColor whiteColor];
    image.layer.masksToBounds = YES;
    image.layer.borderWidth = 0.5;
    image.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
    return image;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
