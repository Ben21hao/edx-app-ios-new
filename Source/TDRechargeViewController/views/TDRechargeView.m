//
//  TDRechargeView.m
//  edX
//
//  Created by Elite Edu on 16/12/4.
//  Copyright © 2016年 edX. All rights reserved.
//

#import "TDRechargeView.h"
#import "TDSelectPayCell.h"
#import "TDSelectPayModel.h"

@interface TDRechargeView ()

@property (nonatomic,strong) UIView *moneyView; //按钮页面
@property (nonatomic,assign) NSInteger type;

@end

@implementation TDRechargeView

- (instancetype)initWithType:(NSInteger)type {
    self = [super init];
    if (self) {
        self.type = type;
        [self setViewConstraint];
    }
    return self;
}

- (void)setViewConstraint {
    self.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self);
    }];
    
    self.tableView.tableHeaderView = [self setTableviewHeaderView];
    self.tableView.tableFooterView = [self setTableViewFooterView];
}

#pragma mark - 选择价格
- (void)moneyButtonAction:(UIButton *)sender {
    [self.inputField resignFirstResponder];
    
    if (!sender.selected) {
        /*先将之前选中的还原*/
        self.selectedButton.backgroundColor = [UIColor whiteColor];
        self.selectedButton.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
        [self.selectedButton setAttributedTitle:[self setNoneSelectMoneyStr:[NSString stringWithFormat:@"￥%@",self.moneyArray[self.selectedButton.tag]]] forState:UIControlStateNormal];
        self.selectedButton.selected = NO;
        
        /*再将现在选中的设置为相应地格式*/
        sender.selected = YES;
        sender.backgroundColor = [UIColor colorWithHexString:colorHexStr4];
        sender.layer.borderColor = [UIColor colorWithHexString:colorHexStr4].CGColor;
        NSMutableAttributedString *title = [self selectedButtonAttributeMoneyStr:[NSString stringWithFormat:@"￥%@\n",self.moneyArray[sender.tag]] withBaodianStr:[NSString stringWithFormat:@"%d %@",[self.moneyArray[sender.tag] intValue] * 10,NSLocalizedString(@"COINS_VALUE", nil)]];
        [sender setAttributedTitle:title forState:UIControlStateSelected];
        
        self.selectedButton = sender;
        if (self.selectMoneyButtonHandle) {
            self.selectMoneyButtonHandle(sender.tag);
        }
    }
}

#pragma mark - data
- (void)setMoneyViewData:(NSArray *)moneyArray withType:(NSInteger)type { //1 选中第一个；2 都不选中
    _moneyArray = moneyArray;
    for (int i = 0; i < _moneyArray.count; i ++) {
        UIButton *moneyButton = [[UIButton alloc] init];
        moneyButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        moneyButton.titleLabel.numberOfLines = 0;
        moneyButton.layer.cornerRadius = 4.0;
        moneyButton.layer.borderWidth = 1.0;
        moneyButton.layer.borderColor = [UIColor colorWithHexString:colorHexStr6].CGColor;
        moneyButton.backgroundColor = [UIColor whiteColor];
        [self.moneyView addSubview:moneyButton];
        
        int width = (TDWidth - 72) / 3;
        int index = i % 3;
        int range = i / 3;
        [moneyButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.moneyView.mas_left).offset(index * (width + 18));
            make.top.mas_equalTo(range * 75);
            make.size.mas_equalTo(CGSizeMake(width, 60));
        }];
        
        //设置按钮标题
        [moneyButton setAttributedTitle:[self setNoneSelectMoneyStr:[NSString stringWithFormat:@"￥%@",_moneyArray[i]]] forState:UIControlStateNormal];
        moneyButton.tag = i;
        [moneyButton addTarget:self action:@selector(moneyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        if (i == 0 && type == 1) {
            moneyButton.backgroundColor = [UIColor colorWithHexString:colorHexStr4];
            NSMutableAttributedString *title = [self selectedButtonAttributeMoneyStr:[NSString stringWithFormat:@"￥%@\n",_moneyArray[i]] withBaodianStr:[NSString stringWithFormat:@"%d %@",[_moneyArray[i] intValue] * 10,NSLocalizedString(@"COINS_VALUE", nil)]];
            [moneyButton setAttributedTitle:title forState:UIControlStateSelected];
            moneyButton.selected = YES;
            self.selectedButton = moneyButton;
        }
    }
}

//选择按钮的颜色
- (NSMutableAttributedString *)selectedButtonAttributeMoneyStr:(NSString *)moneyStr withBaodianStr:(NSString *)bStr {
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:moneyStr
                                                                             attributes:@{
                                                                                          NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],
                                                                                          NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                                          }];
    NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:bStr
                                                                             attributes:@{
                                                                                          NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:11],
                                                                                          NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                                          }];
    [str1 appendAttributedString:str2];
    return str1;
}

- (NSMutableAttributedString *)setNoneSelectMoneyStr:(NSString *)moneyStr {
    NSMutableAttributedString *str1 = [[NSMutableAttributedString alloc] initWithString:moneyStr
                                                                             attributes:@{
                                                                                          NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:14],
                                                                                          NSForegroundColorAttributeName : [UIColor colorWithHexString:colorHexStr9]
                                                                                          }];
    return str1;
}

#pragma mark - 表头
- (UIView *)setTableviewHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, self.type == 1 ? 279 : 228)];
    headerView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestrure)];
    [headerView addGestureRecognizer:gesture];
    
    self.topLabel = [[UILabel alloc] init];
    self.topLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.topLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [headerView addSubview:self.topLabel];

    self.moneyView = [[UIView alloc] init];
    [headerView addSubview:self.moneyView];
    
    self.inputField = [[UITextField alloc] init];
    self.inputField.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.inputField.placeholder = NSLocalizedString(@"ENTER_OTHERPRICE", nil);
    self.inputField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputField.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.inputField.backgroundColor = [UIColor whiteColor];
    self.inputField.textAlignment = NSTextAlignmentCenter;
    self.inputField.keyboardType = UIKeyboardTypeNumberPad;
    [headerView addSubview:self.inputField];
    
    self.exchangeLabel = [[UILabel alloc] init];
    self.exchangeLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    self.exchangeLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    [headerView addSubview:self.exchangeLabel];
    
    self.exchangeLabel.hidden = self.type == 1 ? NO : YES;
    self.inputField.hidden = self.type == 1 ? NO : YES;
    
    [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(headerView.mas_left).offset(18);
        make.top.mas_equalTo(headerView.mas_top).offset(18);
    }];
    
    [self.moneyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(headerView.mas_left).offset(18);
        make.right.mas_equalTo(headerView.mas_right).offset(-18);
        make.top.mas_equalTo(self.topLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(150);
    }];
    
    [self.inputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(headerView.mas_left).offset(18);
        make.right.mas_equalTo(headerView.mas_right).offset(-18);
        make.top.mas_equalTo(self.moneyView.mas_bottom).offset(0);
        make.height.mas_equalTo(42);

    }];
    
    [self.exchangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(headerView.mas_centerX);
        make.top.mas_equalTo(self.inputField.mas_bottom).offset(8);
    }];
    
    return headerView;
}

#pragma mark - 表尾
- (UIView *)setTableViewFooterView {
    UIView *footerVeiw = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TDWidth, self.type == 1 ? 108 : 58)];
    footerVeiw.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestrure)];
    [footerVeiw addGestureRecognizer:gesture];
    
    self.rechargeButton = [[UIButton alloc] init];
    self.rechargeButton.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    [self.rechargeButton setTitle:NSLocalizedString(@"SURE_RECHARGE", nil) forState:UIControlStateNormal];
    self.rechargeButton.layer.cornerRadius = 4.0;
    [footerVeiw addSubview:self.rechargeButton];
    
    [self.rechargeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(footerVeiw.mas_left).offset(18);
        make.right.mas_equalTo(footerVeiw.mas_right).offset(-18);
        make.centerY.mas_equalTo(footerVeiw.mas_centerY);
        make.height.mas_equalTo(42);
    }];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 39, 39)];
    [self.activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [footerVeiw addSubview:self.activityView];
    
    [self.activityView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.rechargeButton.mas_right).offset(-8);
        make.centerY.mas_equalTo(self.rechargeButton.mas_centerY);
    }];
    
    return footerVeiw;
}

- (void)tapGestrure {
    [self.inputField resignFirstResponder];
    
}


@end


