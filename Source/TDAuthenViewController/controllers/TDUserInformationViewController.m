//
//  TDUserInformationViewController.m
//  edX
//
//  Created by Ben on 2017/4/26.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDUserInformationViewController.h"
#import "TDInformationDetailViewController.h"

#import "TDUserInformationView.h"
#import "TDUserInformationCell.h"
#import "TDBaseToolModel.h"

@interface TDUserInformationViewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (nonatomic,strong) TDUserInformationView *messageView;

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *identifyID;
@property (nonatomic,strong) NSString *birthDate;
@property (nonatomic,strong) NSString *sexStr;
@property (nonatomic,strong) TDBaseToolModel *baseTool;
@property (nonatomic,assign) BOOL isHandin;

@end

@implementation TDUserInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setViewConstraint];
    
    self.baseTool = [[TDBaseToolModel alloc] init];
    self.isHandin = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.titleViewLabel.text = NSLocalizedString(@"AUTHENTICATION_MESSAGE", nil);
}

- (void)backButtonAction:(UIButton *)sender {
    if (self.isHandin == YES) {
        [self.view makeToast:NSLocalizedString(@"SUBMIT_ING", nil) duration:0.8 position:CSToastPositionCenter];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 提交
- (void)handinButtonAciton:(UIButton *)sender {
    NSLog(@" 提交 == -=-=-==-=-=-= ");
    
    [self resignFirstResponderAction];
    
    [self.messageView.activityView startAnimating];
    [self.messageView.handinButton setTitle:NSLocalizedString(@"SUBMIT_ING", nil) forState:UIControlStateNormal];
    
    if (self.isHandin == YES) {
        return;
    }
    if (![self judgeMessageTrue]) {
        [self stopHandingHandle];
        return;
    }
    self.isHandin = YES;
    
    NSString *faceStr = [self base64Code:self.faceImage];
    NSString *identifyStr = [self base64Code:self.identifyImage];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setValue:self.username forKey:@"username"];
    [dic setValue:faceStr forKey:@"face_image"];
    [dic setValue:identifyStr forKey:@"identity_image"];
    [dic setValue:self.name forKey:@"name"];
    [dic setValue:self.identifyID forKey:@"identityid"];
    [dic setValue:self.birthDate forKey:@"birthdate"];
    [dic setValue:[self.sexStr isEqualToString:NSLocalizedString(@"TD_MAN", nil)] ? @"m" : @"f" forKey:@"gender"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/users/authentication/handin_message/",ELITEU_URL];
    
    [manager POST:url parameters:dic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self stopHandingHandle];
        self.isHandin = NO;
        
        NSDictionary *responseDic = (NSDictionary *)responseObject;
        id code = responseDic[@"code"];
        if ([code intValue] == 200 || [code intValue] == 401) { //200 提交成功 ；401 重复提交
            
            TDInformationDetailViewController *messageVC = [[TDInformationDetailViewController alloc] init];
            messageVC.username = self.username;
            messageVC.whereFrom = TDAuthenMessageFromAuthen;
            [self.navigationController pushViewController:messageVC animated:YES];
            
        } else { // 300 提交失败
            [self.view makeToast:NSLocalizedString(@"FALILED_SUBMIT", nil) duration:1.08 position:CSToastPositionCenter];
        }
        NSLog(@"msg---- %@ +++ responseDic ==== %@",responseDic[@"msg"],responseDic);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self stopHandingHandle];
        self.isHandin = NO;
        [self.view makeToast:NSLocalizedString(@"NETWORK_CONNET_FAIL", nil) duration:1.08 position:CSToastPositionCenter];
        NSLog(@"认证出错 ---- %ld",(long)error.code);
    }];
}

- (void)stopHandingHandle {
    [self.messageView.activityView stopAnimating];
    [self.messageView.handinButton setTitle:NSLocalizedString(@"SUBMIT", nil) forState:UIControlStateNormal];
}

- (BOOL)judgeMessageTrue {
    if (![self.baseTool networkingState]) {
        [self.view makeToast:NSLocalizedString(@"NETWORK_NOT_AVAILABLE_TITLE", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (self.name.length == 0) {
        [self.view makeToast:NSLocalizedString(@"ENTE_REAL_NAME", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (![self.baseTool isValidateUserName:self.name]) {
        [self.view makeToast:NSLocalizedString(@"CHINESE_NAME", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if ( self.name.length == 1) {
        [self.view makeToast:NSLocalizedString(@"ENTER_ALL_NAME", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (self.identifyID.length == 0) {
        [self.view makeToast:NSLocalizedString(@"ENTER_CARD_ID", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (![self.baseTool isValidateIdentify:self.identifyID]) {
        [self.view makeToast:NSLocalizedString(@"CARD_ID_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (self.birthDate.length == 0) {
        [self.view makeToast:NSLocalizedString(@"ENTET_BIRTH_DATE", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
        
    } else if (self.sexStr.length == 0) {
        [self.view makeToast:NSLocalizedString(@"SELECT_SEX", nil) duration:1.08 position:CSToastPositionCenter];
        return NO;
    }
    return YES;
}

- (NSString *)base64Code:(UIImage *)image {
    
//    NSData *faceData = UIImagePNGRepresentation(image);
    NSData *faceData = UIImageJPEGRepresentation(image, 1.0);
    NSString *faceStr = [faceData base64EncodedStringWithOptions:0];
    return faceStr;
}

#pragma mark - UI
- (void)setViewConstraint {
    self.messageView = [[TDUserInformationView alloc] init];
    self.messageView.tableView.delegate = self;
    self.messageView.tableView.dataSource = self;
    [self.messageView.handinButton addTarget:self action:@selector(handinButtonAciton:) forControlEvents:UIControlEventTouchUpInside];
    
    WS(weakSelf);
    self.messageView.selectDateHandle = ^(NSString *dateStr){
        weakSelf.birthDate = dateStr;
    };
    self.messageView.selectSexHandle = ^(NSString *sexStr){
        weakSelf.sexStr = sexStr;
    };
    [self.view addSubview:self.messageView];
    
    [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.view);
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.messageView.tableView.tableFooterView addGestureRecognizer:tapGesture];
    UITapGestureRecognizer *tapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.messageView.tableView.tableHeaderView addGestureRecognizer:tapGesture1];
}

#pragma mark - 点击空白处
- (void)tapAction:(UITapGestureRecognizer *)sender {
    
    [self resignFirstResponderAction];
}

- (void)resignFirstResponderAction {
    
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.5 animations:^{
        self.messageView.dateView.frame = CGRectMake(0, TDHeight, TDWidth, 0);
    }];
}

#pragma mark - tableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    TDUserInformationCell *cell = [[TDUserInformationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MessageCell"];
    
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
    [cell addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(cell);
        make.height.mas_equalTo(0.5);
    }];
    
    cell.selectionStyle = UITableViewCellSeparatorStyleNone;
    cell.detailTextField.userInteractionEnabled = NO;
    cell.detailTextField.delegate = self;
    cell.detailTextField.tag = indexPath.row;
    cell.backgroundColor = [UIColor whiteColor];
    
    switch (indexPath.row) {
        case 0:
            cell.titleLabel.text = NSLocalizedString(@"TRURE_NAME", nil);
            cell.detailTextField.placeholder = NSLocalizedString(@"ENTE_REAL_NAME", nil);
            cell.detailTextField.text = self.name;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailTextField.userInteractionEnabled = YES;
            cell.isDisclosure = NO;
            break;
        case 1:
            cell.titleLabel.text = NSLocalizedString(@"CARD_ID", nil);
            cell.detailTextField.placeholder = NSLocalizedString(@"ENTER_CARD_ID", nil);
            cell.detailTextField.text = self.identifyID;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailTextField.userInteractionEnabled = YES;
            cell.isDisclosure = NO;
            break;
        case 2:
            cell.titleLabel.text = NSLocalizedString(@"USER_BIRTHDATE", nil);
            //            cell.detailTextField.placeholder = NSLocalizedString(@"ENTET_BIRTH_DATE", nil);
            cell.detailTextField.text = self.birthDate;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 3: {
            cell.titleLabel.text = NSLocalizedString(@"USER_SEX", nil);
            //            cell.detailTextField.placeholder = NSLocalizedString(@"SELECT_SEX", nil);
            cell.detailTextField.text = self.sexStr;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [UIColor colorWithHexString:colorHexStr7];
            [cell addSubview:line];
            [line mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.mas_equalTo(cell);
                make.height.mas_equalTo(0.5);
            }];
        }
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.view endEditing:YES];
    if (indexPath.row == 2 || indexPath.row == 3) {
        NSInteger height = 268;
        if (indexPath.row == 2) {
            self.messageView.isDate = YES;
        } else {
            self.messageView.isDate = NO;
            height = 198;
        }
        [UIView animateWithDuration:0.5 animations:^{
            self.messageView.dateView.frame = CGRectMake(0, TDHeight - height, TDWidth, height);
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

#pragma mark - textField Delegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField.tag == 0) {
        self.name = textField.text;
        
        if (![self.baseTool isValidateUserName:self.name] && textField.text.length != 0) {
            [self.view makeToast:NSLocalizedString(@"CHINESE_NAME", nil) duration:1.08 position:CSToastPositionCenter];
        }
        
    } else if (textField.tag == 1) {
        self.identifyID = textField.text;
        
        if (![self.baseTool isValidateIdentify:self.identifyID] && textField.text.length != 0) {
            [self.view makeToast:NSLocalizedString(@"CARD_ID_ERROR", nil) duration:1.08 position:CSToastPositionCenter];
            return;
        }
    }
    
    NSLog(@" ----输入---- %@",textField.text);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
