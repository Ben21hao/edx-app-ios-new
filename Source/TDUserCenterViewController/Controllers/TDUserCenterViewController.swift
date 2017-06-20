//
//  TDUserCenterViewController.swift
//  edX
//
//  Created by Elite Edu on 17/4/14.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDUserCenterViewController: OfflineSupportViewController,UITableViewDelegate,UserProfilePresenterDelegate {
    typealias Environment = protocol<
        OEXAnalyticsProvider,
        OEXConfigProvider,
        NetworkManagerProvider,
        OEXRouterProvider,
        ReachabilityProvider
    >
    private let environment : Environment
    private let editable: Bool
    let session = OEXRouter.sharedRouter().environment.session
    
    private let tableView = UITableView.init()
    private let loadController = LoadStateViewController()
    private let contentView = TDUserCenterView(frame: CGRectZero)
    
    private let presenter : UserProfilePresenter
    convenience init(environment : protocol<UserProfileNetworkPresenter.Environment, Environment>, username : String, editable: Bool) {
        
        let presenter = UserProfileNetworkPresenter(environment: environment, username: username)
        self.init(environment: environment, presenter: presenter, editable: editable)
        presenter.delegate = self
    }
    
    init(environment: Environment, presenter: UserProfilePresenter, editable: Bool) {
        self.editable = editable
        self.environment = environment
        self.presenter = presenter
        super.init(env: environment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewConstraint()
//        setRightNavigationBar()
        
        addProfileListener()//数据请求
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.titleViewLabel.text = Strings.userCenter
        
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenProfileView)
        presenter.refresh()
    }
    
    override func reloadViewData() {
        presenter.refresh()
    }
    
    private func addProfileListener() {
        let editable = self.editable
        let networkManager = environment.networkManager
        
        presenter.profileStream.listen(self, success: { [weak self] profile in
            
            // TODO: Refactor UserProfileView to take a dumb model so we don't need to pass it a network manager
            self?.contentView.populateFields(profile, editable: editable, networkManager: networkManager)
            self?.loadController.state = .Loaded
            
            }, failure : { [weak self] error in
                self?.loadController.state = LoadState.failed(error, message: Strings.Profile.unableToGet)
            })
    }
    
    //MARK: UI
    func setUpViewConstraint() {
        
        self.contentView.clickHeaderImageHandle = { () in
            self.gotoAuthenVc()
        }
        self.contentView.tableView.delegate = self
        self.view.addSubview(self.contentView)
        
        self.contentView.snp_makeConstraints {make in
            make.left.right.bottom.top.equalTo(self.view)
        }
    }
    
    func setRightNavigationBar() {
        
        let rightButton = UIButton.init(frame: CGRectMake(0, 0, 68, 48))
        rightButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, -16)
        rightButton.titleLabel?.font = UIFont.init(name: "OpenSans", size: 16.0)
        rightButton.titleLabel?.textAlignment = .Right
        rightButton.showsTouchWhenHighlighted = true
        rightButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        rightButton.setTitle(Strings.edit, forState: .Normal)
        rightButton.addTarget(self, action: #selector(rightButtonAciton), forControlEvents: .TouchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rightButton)
    }
    
    func rightButtonAciton() {//编辑
        if editable {
            self.environment.router?.showProfileEditorFromController(self)
        }
    }
    
    func gotoAuthenVc() {//身份验证
        if contentView.statusCode == 400  { // 400 未认证
            let photoViewController = TDTakePictureViewController()
            photoViewController.username = session.currentUser?.username
            self.navigationController?.pushViewController(photoViewController, animated: true)
            
        } else if contentView.statusCode == 200 || contentView.statusCode == 202 { //200 提交成功，202 认证失败
            let messageShowController = TDInformationDetailViewController()
            messageShowController.username = session.currentUser?.username
            self.navigationController?.pushViewController(messageShowController, animated: true)
            
        } else if contentView.statusCode == 201 { //已认证
            let successViewController = TDAuthenSuccessViewController()
            self.navigationController?.pushViewController(successViewController, animated: true)
        }
    }
    
    func gotoCouponVc() { //优惠券
//        let userCouponVC = UserYouViewController()
//        let firstVC = UserFirstViewController()
//        let currentUser = session.currentUser?.username  //传当前用户名
//        firstVC.username = currentUser
//        userCouponVC.username = currentUser
//        self.navigationController?.pushViewController(userCouponVC, animated: true)
        
        let userCouponVC = TDCouponViewController()
        userCouponVC.username = session.currentUser?.username //传当前用户名
        self.navigationController?.pushViewController(userCouponVC, animated: true)
        
    }
    
    func gotoRechargeCoinVc() { //充值宝典
        let userCouponVC1 = TDRechargeViewController()
        userCouponVC1.username = session.currentUser?.username //传当前用户名
        self.navigationController?.pushViewController(userCouponVC1, animated: true)
    }
    
    func gotoWaiForPayVc() { //待支付订单
        let userCouponVC1 = WaitForPayViewController()
        userCouponVC1.username = session.currentUser?.username  //传当前用户名
        self.navigationController?.pushViewController(userCouponVC1, animated: true)
    }

    func gotoAssistantServiceVc() {
        let assistantVc = TDAssistantServiceViewController()
        assistantVc.username = session.currentUser?.username
        self.navigationController?.pushViewController(assistantVc, animated: true)
    }
    
    //MARK: tableview Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 98 : 75;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 8 : 0;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0 {
            if editable {
                self.environment.router?.showProfileEditorFromController(self)
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                gotoRechargeCoinVc()
            case 1:
                gotoCouponVc()
            default:
                gotoWaiForPayVc()
            }
        } else {
            if indexPath.row == 0 {
                self.view.makeToast("预约讲座", duration: 1.08, position: CSToastPositionCenter)
            } else {
                gotoAssistantServiceVc()
            }
        }
    }
    
    //MARK: UserProfilePresenterDelegate
    func presenter(presenter: UserProfilePresenter, choseShareURL url: NSURL) {
        let message = Strings.Accomplishments.shareText(platformName:self.environment.config.platformName())
        let controller = UIActivityViewController(
            activityItems: [message, url],
            applicationActivities: nil
        )
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

