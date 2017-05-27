//
//  TDCourseIntroduceCell.swift
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDCourseIntroduceCell: UITableViewCell {
    
    let bgView = UIView()
    let introduceLabel = UILabel()
    let moreButton = UIButton()    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.whiteColor()
        configView()
        setViewConstraint()
    }
    
    func configView() {
        bgView.backgroundColor = UIColor.whiteColor()
        self.addSubview(bgView)
        
        introduceLabel.numberOfLines = 0
        introduceLabel.font = UIFont.init(name: "OpenSans", size: 14)
        introduceLabel.textColor = OEXStyles.sharedStyles().baseColor9()
        introduceLabel.textAlignment = .Natural
        bgView.addSubview(introduceLabel)
        
        moreButton.titleLabel?.font = UIFont.init(name: "OpenSans", size: 14)
        moreButton.setTitleColor(OEXStyles.sharedStyles().baseColor1(), forState: .Normal)
        moreButton.setTitle(Strings.allText, forState: .Normal)
        
        bgView.addSubview(moreButton)
        
    }
    
    func setViewConstraint() {
        bgView.snp_makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self)
        }
        
        moreButton.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.bottom.equalTo(bgView.snp_bottom).offset(0)
//            make.size.equalTo(CGSizeMake(78, 33))
        }
        moreButton.titleLabel?.sizeToFit()
        
        introduceLabel.snp_makeConstraints { (make) in
            make.top.equalTo(bgView.snp_top).offset(0)
            make.left.equalTo(bgView.snp_left).offset(18)
            make.right.equalTo(bgView.snp_right).offset(-18)
            make.bottom.equalTo(moreButton.snp_top).offset(0)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


