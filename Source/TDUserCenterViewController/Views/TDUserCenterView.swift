//
//  TDUserCenterView.swift
//  edX
//
//  Created by Elite Edu on 17/4/14.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDUserCenterView: UIView,UITableViewDataSource {
    
    internal let tableView = UITableView()
    
    internal var score = Double()//宝典
    internal var statusCode = Int() //认证状态 400 未认证，200 提交成功 ，201 已认证，202 认证失败
    internal var coupons = Double()//优惠券
    internal var orders = Double()//订单
    
    private let toolModel = TDBaseToolModel.init()
    private var isHidePuchase = true //默认隐藏内购
    
    typealias clickHeaderImageBlock = () -> ()
    var clickHeaderImageHandle : clickHeaderImageBlock?
    
    var userProfile: UserProfile?
    var networkManager: NetworkManager?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setViewConstraint()
       
        toolModel.showPurchase()
        toolModel.judHidePurchseHandle = {(isHide:Bool?)in  //yes 不用内购；no 使用内购
            self.isHidePuchase = isHide!
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: UI
    func setViewConstraint() {
        
        self.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        self.tableView.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        self.tableView.tableFooterView = UIView.init()
        self.tableView.dataSource = self
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)

        self.addSubview(self.tableView)
        self.tableView.snp_makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self)
        }
    }
    
    func populateFields(profile: UserProfile, editable : Bool, networkManager : NetworkManager) {

        //认证状态 -- 400 未认证，200 提交成功 ，201 已认证，202 认证失败
        statusCode = profile.statusCode!

        self.userProfile = profile
        self.networkManager = networkManager
        
        self.score = profile.remainscore! //学习宝典
        self.coupons = profile.coupon! //优惠券
        self.orders = profile.order! //未支付订单
        self.tableView.reloadData()
    }
    
    //MARK: tableview Datasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            if self.isHidePuchase == true {
                return 3
            } else {
                return 1
            }
        } else {
//           return 2
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //邮箱或手机
        let baseTool = TDBaseToolModel.init()
        
        if indexPath.section == 0 {
            let cell = TDUserMessageCell.init(style: .Default, reuseIdentifier: "UserMessageCell")
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .None
            
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(gotoAuthenVc))
            cell.headerImageView.addGestureRecognizer(tap)
            
            if self.userProfile != nil {
                
                //用户名
                if self.userProfile!.nickname != nil {
                    cell.nameLabel.text = self.userProfile!.nickname
                } else {
                    if self.userProfile!.name != self.userProfile!.username {
                        cell.nameLabel.text = self.userProfile!.name
                    } else {
                        cell.nameLabel.text = Strings.noName
                    }
                }
                
                if self.userProfile!.phone != nil {
                    let newStr = baseTool.setPhoneStyle(self.userProfile!.phone)
                    cell.acountLabel.text = newStr
                } else {
                    let newStr = baseTool.setEmailStyle(self.userProfile!.email)
                    cell.acountLabel.text = newStr
                }
                
                if self.networkManager != nil {
                    cell.headerImageView.remoteImage = self.userProfile?.image(self.networkManager!)
                }
                
                if statusCode == 400 || statusCode == 202 {
                    cell.statusLabel.text = Strings.tdUnvertified
                    cell.statusLabel.backgroundColor = OEXStyles.sharedStyles().baseColor6()
                    cell.statusLabel.textColor =  OEXStyles.sharedStyles().baseColor8()
                    
                } else if statusCode == 200 {
                    cell.statusLabel.text = Strings.tdProcessing
                    cell.statusLabel.backgroundColor = OEXStyles.sharedStyles().baseColor2()
                    cell.statusLabel.textColor = UIColor.whiteColor()
                    
                } else if statusCode == 201 {
                    cell.statusLabel.text = Strings.tdVertified
                    cell.statusLabel.backgroundColor = OEXStyles.sharedStyles().baseColor4()
                    cell.statusLabel.textColor =  UIColor.whiteColor()
                }
            }
            
            return cell
            
        } else {
            let cell = TDUserCeterCell.init(style: .Default, reuseIdentifier: "UserCenterCell")
            cell.accessoryType = .DisclosureIndicator
            
            var imageStr : String
            var titleStr : String
            
            if indexPath.section == 1 {
                switch indexPath.row {
                case 0:
                    titleStr = Strings.studyCoins
                    cell.messageLabel.attributedText = baseTool.setDetailString(Strings.nowHave(count: String(format: "%.2f",score)), withFont: 12, withColorStr: "#A7A4A4")
                    imageStr = "baodian"
                case 1:
                    titleStr = Strings.couponPaper
                    cell.messageLabel.text = Strings.couponNumber(count:String(format: "%.0f",coupons))
                    imageStr = "coupons"
                default:
                    titleStr = Strings.courseOrder
                    cell.messageLabel.text = Strings.orderCount(count: String(format: "%.0f",orders))
                    imageStr = "Page"
                }
            } else {
                switch indexPath.row {
                case 0:
                    titleStr = "讲座"
                    cell.messageLabel.text = "讲座预约报名"
                    imageStr = "lecture_image"
                default:
                    titleStr = Strings.taService
                    cell.messageLabel.text = Strings.viewTaService
                    imageStr = "assistant_image"
                }
            }
            cell.titleLabel.text = titleStr
            cell.iconImageView.image = UIImage.init(named: imageStr)
            return cell
        }
    }
    
    func gotoAuthenVc() {
        if (clickHeaderImageHandle != nil) {
            clickHeaderImageHandle!()
        }
    }
}
