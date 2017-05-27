//
//  EnrolledCoursesFooterView.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class EnrolledCoursesFooterView : UIView {
    private let promptLabel = UILabel()
    private let findCoursesButton = UIButton(type:.System)
    
    private let container = UIView()
    
    var findCoursesAction : (() -> Void)?
    
    private var findCoursesTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        addSubview(container)
        container.addSubview(promptLabel)
        container.addSubview(findCoursesButton)
        
        self.promptLabel.attributedText = findCoursesTextStyle.attributedStringWithText(Strings.EnrollmentList.findCoursesPrompt)
        self.promptLabel.textAlignment = .Center
        
        self.findCoursesButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.EnrollmentList.findCourses)//.oex_uppercaseStringInCurrentLocale()大写字母
        
        container.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
//        container.applyBorderStyle(BorderStyle())
        container.layer.cornerRadius = 4.0
        container.layer.shadowColor = UIColor.init(RGBHex: 0xaab2bd, alpha: 1).CGColor
        container.layer.shadowOffset = CGSizeMake(0, 1)
        container.layer.shadowOpacity = 0.6
        
        container.snp_makeConstraints {make in
            make.top.equalTo(self).offset(CourseCardCell.margin)
            make.bottom.equalTo(self)
            make.leading.equalTo(self).offset(CourseCardCell.margin)
            make.trailing.equalTo(self).offset(-CourseCardCell.margin)
        }
        
        self.promptLabel.snp_makeConstraints {make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).offset(-StandardHorizontalMargin)
            make.top.equalTo(container).offset(StandardVerticalMargin + 10)
        }
        
        self.findCoursesButton.snp_makeConstraints {make in
            make.leading.equalTo(promptLabel)
            make.trailing.equalTo(promptLabel)
            make.top.equalTo(promptLabel.snp_bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(container).offset(-StandardVerticalMargin - 18)
        }
        
        findCoursesButton.oex_addAction({[weak self] _ in
            self?.findCoursesAction?()
            }, forEvents: .TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
