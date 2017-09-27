//
//  TDCourseMessageCell.swift
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDCourseMessageCell: UITableViewCell {

    let bgView = UIView()
    
    let clockLabel = UILabel() //时钟图标
    let studyLabel = UILabel() //学习时长
    let timeLabel = UILabel()//时间
    let sepLine = UIView()
    
    let peopleLabel = UILabel() //人头图标
    let enrollmentLabel = UILabel() //报名人数
    let numberLabel = UILabel()//人数
    
    let dateLabel = UILabel() //期限图标
    let limitLabel = UILabel() //期限
    let limitMessageLabel = UILabel()//时间限制
    let line2 = UIView()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.whiteColor()
        configView()
        setViewConstraint()
    }
    
    func configView() {
        
        bgView.layer.cornerRadius = 4.0
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = OEXStyles.sharedStyles().baseColor6().CGColor
        bgView.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        self.addSubview(bgView)

        //学习时长
        setIconLabelType("\u{f017}", label: clockLabel)
        bgView.addSubview(clockLabel)
        
        setTitleLabelType(Strings.studyTime, label: studyLabel)
        bgView.addSubview(studyLabel)
        
        setTitleLabelType("", label: timeLabel)
        bgView.addSubview(timeLabel)
        
        bgView.addSubview(sepLine)
        sepLine.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        
        //报名人数
        setIconLabelType("\u{f007}", label: peopleLabel)
        bgView.addSubview(peopleLabel)
        
        setTitleLabelType(Strings.applicationNumber, label: enrollmentLabel)
        bgView.addSubview(enrollmentLabel)
        
        setTitleLabelType("", label: numberLabel)
        bgView.addSubview(numberLabel)//人数
        
        line2.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        bgView.addSubview(line2)
        
        //学习期限
        setIconLabelType("\u{f274}", label: dateLabel)
        bgView.addSubview(dateLabel)
        
        setTitleLabelType(Strings.dateLimit, label: limitLabel)
        bgView.addSubview(limitLabel)
        
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.lineSpacing = 2
        let str1 = NSMutableAttributedString.init(string: "\(Strings.noLimit)\n", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(14),NSForegroundColorAttributeName : OEXStyles.sharedStyles().baseColor10(),NSParagraphStyleAttributeName : paragraph])
        let str2 = NSMutableAttributedString.init(string: Strings.enrollMessage, attributes: [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 12)!,NSForegroundColorAttributeName : OEXStyles.sharedStyles().baseColor9(),NSParagraphStyleAttributeName : paragraph])
        str1.appendAttributedString(str2)
        
        limitMessageLabel.attributedText = str1
        limitMessageLabel.numberOfLines = 0;
        limitMessageLabel.lineBreakMode = .ByWordWrapping //以单词为单位换行
        bgView.addSubview(limitMessageLabel)
    }
    
    func setIconLabelType(imageStr: String, label: UILabel) {
    
        label.font = UIFont.init(name: "FontAwesome", size: 20)
        label.text = imageStr
        label.textColor = UIColor.init(RGBHex: 0xaab2bd, alpha: 1)
    }
    
    func setTitleLabelType(titleStr: String, label: UILabel) {
        label.text = titleStr
        label.font = UIFont.systemFontOfSize(14)
        label.textColor = OEXStyles.sharedStyles().baseColor10()
    }
    
    func setViewConstraint() {
        
        bgView.snp_makeConstraints { (make) in
            make.left.equalTo(self.snp_left).offset(18)
            make.right.equalTo(self.snp_right).offset(-18)
            make.top.equalTo(self.snp_top).offset(3)
            make.bottom.equalTo(self.snp_bottom).offset(-3)
        }
        
        clockLabel.snp_makeConstraints { (make) in
            make.top.equalTo(bgView.snp_top).offset(18)
            make.left.equalTo(bgView.snp_left).offset(18)
        }
        
        studyLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(clockLabel.snp_centerY)
            make.left.equalTo(clockLabel.snp_right).offset(20)
            make.height.equalTo(48)
        }
        
        timeLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(clockLabel.snp_centerY)
            make.left.equalTo(bgView.snp_left).offset(153)
            make.height.equalTo(48)
        }

        sepLine.snp_makeConstraints { (make) in
            make.top.equalTo(bgView.snp_top).offset(48)
            make.leading.equalTo(bgView.snp_leading).offset(6)
            make.trailing.equalTo(bgView.snp_trailing).offset(-6)
            make.height.equalTo(1)
        }

        peopleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(sepLine.snp_bottom).offset(13)
            make.left.equalTo(bgView.snp_left).offset(18)
        }
 
        enrollmentLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(peopleLabel.snp_centerY)
            make.left.equalTo(studyLabel.snp_left)
            make.height.equalTo(48)
        }

        numberLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(peopleLabel.snp_centerY)
            make.left.equalTo(bgView.snp_left).offset(153)
            make.height.equalTo(48)
        }

        line2.snp_makeConstraints { (make) in
            make.top.equalTo(bgView.snp_top).offset(96)
            make.leading.equalTo(bgView.snp_leading).offset(6)
            make.trailing.equalTo(bgView.snp_trailing).offset(-6)
            make.height.equalTo(1)
        }

        dateLabel.snp_makeConstraints { (make) in
            make.top.equalTo(line2.snp_bottom).offset(13)
            make.left.equalTo(bgView.snp_left).offset(18)
        }

        limitLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(dateLabel.snp_centerY)
            make.left.equalTo(studyLabel.snp_left)
            make.height.equalTo(48)
        }
        
        limitMessageLabel.snp_makeConstraints { (make) in
            make.top.equalTo(line2.snp_bottom).offset(13)
            make.left.equalTo(bgView.snp_left).offset(153)
            make.right.equalTo(bgView.snp_right).offset(-8)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
