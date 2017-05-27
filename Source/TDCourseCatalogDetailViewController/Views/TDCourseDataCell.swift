//
//  TDCourseDataCell.swift
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDCourseDataCell: UITableViewCell {

    let bgView = UIView()
    let leftLabel = UILabel()
    let titleLabel = UILabel()
    let line = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.whiteColor()
        configView()
        setViewConstraint()
    }
    
    func configView() {
        bgView.backgroundColor = UIColor.whiteColor()
        self.contentView.addSubview(bgView)

        leftLabel.font = UIFont.init(name: "FontAwesome", size: 20)
        leftLabel.text = "\u{f0c0}"
        leftLabel.textAlignment = .Center
        leftLabel.textColor = UIColor.whiteColor()
        leftLabel.backgroundColor = OEXStyles.sharedStyles().baseColor1()
        leftLabel.layer.masksToBounds = true
        leftLabel.layer.cornerRadius = 6
        bgView.addSubview(leftLabel)
        
        titleLabel.font = UIFont.init(name: "OpenSans", size: 16)
        titleLabel.textColor = OEXStyles.sharedStyles().baseColor10()
        bgView.addSubview(titleLabel)
        
        line.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        self.addSubview(line)
    }
    
    func setViewConstraint() {
        bgView.snp_makeConstraints { (make) in
            make.left.right.top.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(1)
        }
        
        leftLabel.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.centerY.equalTo(bgView.snp_centerY);
            make.size.equalTo(CGSizeMake(30, 30))
        }
        
        titleLabel.snp_makeConstraints { (make) in
            make.left.equalTo(leftLabel.snp_right).offset(18)
            make.centerY.equalTo(bgView.snp_centerY);
        }
        
        line.snp_makeConstraints { (make) in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


