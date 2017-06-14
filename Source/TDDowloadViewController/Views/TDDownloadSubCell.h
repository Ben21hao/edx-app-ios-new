//
//  TDDownloadSubCell.h
//  edX
//
//  Created by Ben on 2017/6/13.
//  Copyright © 2017年 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OEXCheckBox;

@interface TDDownloadSubCell : UITableViewCell

@property (nonatomic,strong) UIImageView *img_VideoWatchState;//图片
@property (nonatomic,strong) UILabel *lbl_Title; //课程名字
@property (nonatomic,strong) UILabel *lbl_Time; //时间
@property (nonatomic,strong) UILabel *lbl_Size; //大小
@property (nonatomic,strong) OEXCheckBox *btn_CheckboxDelete;

@end
