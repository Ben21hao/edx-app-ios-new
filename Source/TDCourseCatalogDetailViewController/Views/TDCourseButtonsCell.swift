//
//  TDCourseButtonsCell.swift
//  edX
//
//  Created by Ben on 2017/5/5.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDCourseButtonsCell: UITableViewCell {
    let bgView = UIView()
    let submitButton = UIButton()
    let discountLabel = UILabel()
    let auditionButton = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = UIColor.whiteColor()
        configView()
        setViewConstraint()
    }
    
    var submitType : Int = 0 {
        didSet {
            auditionButton.snp_remakeConstraints { (make) in
                make.left.equalTo(bgView.snp_left).offset(18)
                make.right.equalTo(bgView.snp_right).offset(-18)
                make.top.equalTo(bgView.snp_top).offset(0)
                make.height.equalTo(0)
            }
        }
    }
    
    func configView() {
        bgView.backgroundColor = UIColor.whiteColor()
        self.addSubview(bgView)
        
        setButtonStyle(OEXStyles.sharedStyles().baseColor3(), button: auditionButton)
        bgView.addSubview(auditionButton)
        
        setButtonStyle(OEXStyles.sharedStyles().baseColor1(), button: submitButton)
        bgView.addSubview(submitButton)
        
        discountLabel.font = UIFont.init(name: "OpenSans", size: 12)
        discountLabel.textColor = OEXStyles.sharedStyles().baseColor3()
        discountLabel.numberOfLines = 0
        discountLabel.textAlignment = .Center
        bgView.addSubview(discountLabel)
        
//        auditionButton.setTitle("免费试听", forState: .Normal)
//        self.bgView.backgroundColor = UIColor.redColor()
    }
    
    func setViewConstraint() {
        bgView.snp_makeConstraints { (make) in
            make.left.right.top.equalTo(self)
            make.bottom.equalTo(self).offset(1)
        }
        
        auditionButton.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.right.equalTo(bgView.snp_right).offset(-18)
            make.top.equalTo(bgView.snp_top).offset(8)
            make.height.equalTo(44)
        }

        submitButton.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.right.equalTo(bgView.snp_right).offset(-18)
            make.top.equalTo(auditionButton.snp_bottom).offset(8)
            make.height.equalTo(44)
        }
        
        discountLabel.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.right.equalTo(bgView.snp_right).offset(-18)
            make.top.equalTo(submitButton.snp_bottom).offset(8)
            make.bottom.equalTo(bgView.snp_bottom).offset(-8)
        }
    }
    
    func setButtonStyle(color: UIColor, button: UIButton) {
        button.backgroundColor = color
        button.layer.cornerRadius = 4.0
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.titleLabel?.font = UIFont.init(name: "OpenSans", size: 16)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
