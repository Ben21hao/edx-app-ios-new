//
//  TDUserMessageCell.swift
//  edX
//
//  Created by Elite Edu on 17/4/14.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDUserMessageCell: UITableViewCell {
    
    let imageWidth : CGFloat = 78.0
    
    let bgView = UIView()
    let headerImageView = UIImageView()
    let nameLabel = UILabel()
    let acountLabel = UILabel()
    let statusLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        configView()
        setViewConstraint()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configView() {
        bgView.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        self.contentView.addSubview(bgView)
        
        headerImageView.layer.masksToBounds = true
        headerImageView.layer.cornerRadius = imageWidth/2
        headerImageView.layer.borderWidth = 2.0
        headerImageView.layer.borderColor = UIColor.whiteColor().CGColor
        headerImageView.userInteractionEnabled = true
        bgView.addSubview(headerImageView)
        
        nameLabel.textColor = OEXStyles.sharedStyles().baseColor10()
        nameLabel.font = UIFont.init(name: "OpenSans", size: 14)
        bgView.addSubview(nameLabel)
        
        acountLabel.textColor = OEXStyles.sharedStyles().baseColor8()
        acountLabel.font = UIFont.init(name: "OpenSans", size: 12)
        bgView.addSubview(acountLabel)
        
        statusLabel.font = UIFont.init(name: "OpenSans", size: 12)
        statusLabel.layer.masksToBounds = true
        statusLabel.textAlignment = .Center
        statusLabel.layer.cornerRadius = 10.0
        statusLabel.layer.borderWidth = 0.5
        statusLabel.layer.borderColor = UIColor.whiteColor().CGColor
        if #available(iOS 10.0, *) {
            statusLabel.adjustsFontForContentSizeCategory = true
        } else {
            // Fallback on earlier versions
        }
        bgView.addSubview(statusLabel)
        
        headerImageView.image = UIImage.init(named: "people")
  
    }
    
    func setViewConstraint() {
        bgView.snp_makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self.contentView)
        }
        
        headerImageView.snp_makeConstraints { (make) in
            make.left.equalTo(bgView.snp_left).offset(18)
            make.centerY.equalTo(bgView.snp_centerY)
            make.size.equalTo(CGSizeMake(imageWidth, imageWidth))
        }
        
        nameLabel.snp_makeConstraints { (make) in
            make.left.equalTo(headerImageView.snp_right).offset(18)
            make.bottom.equalTo(bgView.snp_centerY).offset(-1)
        }
        
        acountLabel.snp_makeConstraints { (make) in
            make.left.equalTo(headerImageView.snp_right).offset(18)
            make.top.equalTo(bgView.snp_centerY).offset(3)
        }
        
        statusLabel.snp_makeConstraints { (make) in
            make.centerX.equalTo(headerImageView.snp_centerX)
            make.bottom.equalTo(headerImageView.snp_bottom).offset(5)
            make.size.equalTo(CGSizeMake(68, 20))
        }
    }
}
