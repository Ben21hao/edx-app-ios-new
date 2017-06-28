//
//  TDCourseCatalogDetailViewController.swift
//  edX
//
//  Created by Ben on 2017/5/3.
//  Copyright © 2017年 edX. All rights reserved.
//

import UIKit

class TDCourseCatalogDetailViewController: TDSwiftBaseViewController,UITableViewDelegate {
    
    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider, OEXRouterProvider>
    
    private let environment: Environment
    private let courseStream = BackedStream<(OEXCourse, enrolled: Bool)>()
    let session = OEXRouter.sharedRouter().environment.session
    let baseTool = TDBaseToolModel.init()
    
    var courseModel: OEXCourse
    private let courseID: String
    private let courseName : String
    private let companyID : String
    private let username : String
    
    private var freeTimer: NSTimer?
    private var timeNum: Int = 0
    private var freeFinish = 0
    private var getFree = 0 //是否已经点击了免费试听
    private var gotoStudyView = 0 //0 从前面页面进来；1 从学习界面回来； 2 从不是学习的界面回来
    
    private lazy var loadController = LoadStateViewController()
    private var freeView = TDFreeAlertView() //获取免费试听界面
    
    private lazy var courseDetailView : TDCourseCatalogDetailView = {//UI
        return TDCourseCatalogDetailView(frame: CGRectZero, environment: self.environment)
    }()
    
    var showAllText = false
    var prepareOrder = false
    
    init(environment : Environment, courseModel : OEXCourse) {
        
        self.environment = environment
        self.courseModel = OEXCourse()
        self.courseID = courseModel.course_id!
        self.courseName = courseModel.name!
        self.companyID = self.session.currentUser?.company_id ?? ""
        self.username = self.session.currentUser?.username ?? ""
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = self.session.currentUser //登录状态
        if currentUser == nil {
            NSNotificationCenter.defaultCenter().postNotificationName("OEXSessionEndedNotification", object: nil)
        }
        
        self.titleViewLabel.text = self.courseName
        self.setViewConstraint()
        
        self.loadController.setupInController(self, contentView: courseDetailView)
        
        loadCourseData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appEnterForeground), name: "App_EnterForeground_Free_Course", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(courseStatusHandle), name: "Course_Status_Handle", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.gotoStudyView = 0
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.gotoStudyView == 0 {
            setNilTimer()
        }
        NSUserDefaults.standardUserDefaults().removeObjectForKey("Come_From_Course_Detail")
    }
    
    func loadCourseData() {//数据
        
        let retquestModel = TDRequestBaseModel.init()
        retquestModel.getCourseDetail(self.courseID)
        
        retquestModel.courseDetailHandle = { [weak self] (courseModel) in
            
            self!.courseModel = courseModel
            self!.initialFreeButtonText() //初始化免费试听文本
        }
        retquestModel.requestErrorHandle = {[weak self] error in
            self?.loadController.state = LoadState.failed(error)
        }
    }
    
    func courseStatusHandle() {
        loadCourseData()
    }
    
    //MARK: tableview Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                
                if self.courseModel.moreDescription?.characters.count == 0 && self.courseModel.short_description?.characters.count == 0 {
                    return 0
                }
                
                var introduceStr = " "
                if self.showAllText == true {
                    if self.courseModel.moreDescription != nil {
                        introduceStr = "\(self.courseModel.short_description!)\n\(self.courseModel.moreDescription!)"
                    }
                    
                } else {
                    if self.courseModel.short_description != nil {
                        introduceStr = self.courseModel.short_description!
                    }
                }
//                let size = getSizeForString(introduceStr)
//                return size.height + 48
                
                let size =  getLabelHeightByWidth(TDScreenWidth - 36, title: introduceStr, font: 14)
                return size + 48
                
            } else if indexPath.row == 1 {
                
                let paragraph = NSMutableParagraphStyle.init()
                paragraph.lineSpacing = 2
                let attributes = [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 12)!,NSForegroundColorAttributeName : OEXStyles.sharedStyles().baseColor9(),NSParagraphStyleAttributeName : paragraph]
                
                
                let str = "\(Strings.noLimit)\n\(Strings.enrollMessage)"
                let size = str.boundingRectWithSize(CGSizeMake(TDScreenWidth - 198, TDScreenHeight), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes, context: nil).size
                
                return size.height + 128
                
            } else {
                
                switch self.courseModel.submitType { //0 已购买，1 立即加入, 2 查看待支付，3 即将开课
                case 0:
                    return 60
                case 1:
                    return self.courseModel.give_coin?.floatValue > 0 ? 148 : 118
                case 2:
                    return self.courseModel.give_coin?.floatValue > 0 ? 148 : 118
                default:
                    return 60
                }
            }
        }
        return 60
    }
    
    /* 通过label自适应来计算高度 */
    func getLabelHeightByWidth(width: CGFloat,title: String, font: NSInteger) -> CGFloat {
        let label = UILabel.init(frame: CGRectMake(0, 0, width, 0))
        label.text = title
        label.font = UIFont.init(name: "OpenSans", size: 14)
        label.numberOfLines = 0
        label.sizeToFit()
        let height = label.frame.size.height
        return height
        
    }
    
    /* 通过 字符串 来计算高度 -- 不是很准确*/
    func getSizeForString(str: String) -> CGSize {
        
        let size = str.boundingRectWithSize(CGSizeMake(TDScreenWidth - 58, TDScreenHeight), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 14)!], context: nil).size
        return size
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 18
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.gotoStudyView = 2
        
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                gotoProfessorVc()
            case 1:
                gotoCourseOutlineVc()
            case 2:
                gotoStudyCommentVc()
            case 3:
                gotoClassVc()
            default:
                gotoAssistantVc()
            }
        } 
    }
    
    
    //MARK: 跳转
    internal func gotoProfessorVc() { //主讲教授
        let vc = TDProfessorViewController()
        if courseModel.professor_username != nil {
            vc.professorName = courseModel.professor_username!//教授名字
        }
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    internal func gotoCourseOutlineVc() { //课程大纲
//        let vc = OutlineViewController()
        let vc = TDCourseOutLineViewController()
        vc.courseID = self.courseID
        self.navigationController?.pushViewController(vc, animated: true)
    }
    internal func gotoStudyCommentVc() { //学员评价
        let vc = TDCommentViewController()
        vc.courseID = self.courseID
        vc.userName = self.username;//传当前用户名
        self.navigationController?.pushViewController(vc, animated: true)
    }
    internal func gotoClassVc() { //班级
        let vc = QRViewController();
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    internal func gotoAssistantVc() { //助教
        let vc = TDOrderAssistantViewController();
        vc.whereFrom = 2
        vc.courseId = self.courseID
        vc.myName = self.username
        self.navigationController?.pushViewController(vc, animated: true)
    }

    internal func playVideoAction() { //播放预告
        
        let videoVc = TDVideoPlayerViewController()
        videoVc.url = self.courseModel.intro_video_3rd_url;
        videoVc.courseName = self.courseName
        self.navigationController?.pushViewController(videoVc, animated: true)
    }
    
    func gotoWaitForPayVc () { //待支付
        let waitForPAyVc = WaitForPayViewController()
        waitForPAyVc.username = self.username //传当前用户名
        waitForPAyVc.courseId = self.courseID
        self.navigationController?.pushViewController(waitForPAyVc, animated: true)
    }
    
    func gotoChooseCourseVc() { //选择课表
        
        //        if self.courseModel.is_eliteu_course == true { //英荔课程
        
            let vc = TDChooseCourseViewController();
            vc.username = self.username
            vc.courseID = self.courseID
            self.navigationController?.pushViewController(vc, animated: true)
        
        //        } else {
        //            addOwnCompanyCourseHandle()
        //        }
        
    }
    
    private func showCourseScreen(message message: String? = nil) { //跳到我的课程
        self.environment.router?.showMyCourses(animated: true, pushingCourseWithID:courseID) //跳到商务统计
        
        if let message = message {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(EnrollmentShared.overlayMessageDelay * NSTimeInterval(NSEC_PER_SEC)))
            dispatch_after(after, dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(EnrollmentShared.successNotification, object: message, userInfo: nil)
            }
        }
    }
    
    func addOwnCompanyCourseHandle() { //加入自己公司的课程
        
        let manager = TDRequestManager()
        manager.addOwnCompanyCourse(self.courseID, username: self.username, companyID: self.companyID)
        manager.addOwnCompanyCourseHandle = { (type: NSInteger) -> () in
            
            if type == 200 || type == 400 {
                self.environment.router?.showMyCourses()
            }
        }
    }
    
    func addCourseButtonHandle() { // 点击 免费试听按钮
        switch self.courseModel.submitType { //0 已购买，1 立即加入, 2 查看待支付，3 即将开课
        case 0:
            self.showCourseScreen()
        case 1:
            self.gotoChooseCourseVc()
        case 2:
            self.gotoWaitForPayVc()
        default:
            return
        }
    }
    //MARK: ------->>>  免费试听功能 <<<--------
    
    func initialFreeButtonText() { //初始化试听按钮文本
        
        let seconds = self.courseModel.trial_seconds?.intValue
        if seconds == 0 || seconds == nil {//试听已结束
            
            freeCourseEndedStr()
            print("试听剩余时间 trial_seconds --->>> 为0 或 空")
            
        } else {
            if seconds == -1 || seconds == -2 {//－2 代表未购买未试听 ;－1 代表已购买
                self.courseModel.freeStr = Strings.freeTrial//免费试听30分钟
                
            } else {//试听中
                self.setFreeBttuonText("\(self.courseModel.trial_seconds!)")
            }
        }
        
        let currentUser = self.session.currentUser //登录状态
        if  (currentUser != nil){//已登录
        } else {//未登录
            self.courseModel.freeStr = Strings.freeTrial//免费试听30分钟
        }
        print(" 时间 ----> \(self.courseModel.course_status) --> \(self.courseModel.trial_expire_at)")
        
        
        /* ------> 加入课程按钮设置 <------ */
        if self.courseModel.course_status?.intValue == 4 { //已购买
            self.courseModel.submitType = 0//查看课程
            reloadCourseDetail()
            
        } else {//未购买
            
            let now = NSDate()
            if now.isEarlierThanOrEqualTo(self.courseModel.start_display_info.date) {
                
                self.courseModel.submitType = 3//即将开课
                reloadCourseDetail()
                
            } else {
                
                self.courseModel.submitType = 1//马上加入
                if username != "" {
                    judgeWaitforPayCourse()
                    
                } else {
                    reloadCourseDetail()
                }
            }
        }
    }
    
    func judgeWaitforPayCourse() {
        
        let retquestModel = TDRequestBaseModel.init()
        retquestModel.judgeCurseIsWaitforPay(self.username, courseId: self.courseID)
        
        retquestModel.waitforPayCourseHandle = { [weak self] (isWaitPayCourse) in
            
            if isWaitPayCourse > 0 {
                self!.courseModel.submitType = 2//查看待支付
            }
            self!.reloadCourseDetail()
        }
        
        retquestModel.courseDetailHandle = { [weak self] (courseModel) in
            
            self!.courseModel = courseModel
            self!.initialFreeButtonText() //初始化免费试听文本
        }
    }
    
    func reloadCourseDetail() {
        self.courseDetailView.applyCourse(self.courseModel)//渲染显示数据
        self.loadController.state = .Loaded
    }
    
    func addAuditionButtonHandle() { // 点击 免费试听按钮
        
        if freeFinish == 1 { //试听结束 - 功能为加入课程一样
            addCourseButtonHandle()
            
        } else {
            let currentUser = session.currentUser //登录状态
            
            if  (currentUser != nil || self.getFree == 1){ //已登录 / 已点击了立即试听
                if (self.courseModel.course_status?.intValue == 3) { //试听结束 - 功能为加入课程一样
                    
                } else if (self.courseModel.course_status?.intValue == 4) { //已购买
                    self.showCourseScreen() //到商务统计 -- 已购买课程详情
                    
                } else {
                    self.freeExperienceAction() //加入指定课程到试听课
                }
                
            } else {//未登录，弹框输入手机号
                showInputFreeview()
            }
        }
    }
    
    func showInputFreeview() { //显示可输入的弹框
        
        self.freeView = TDFreeAlertView.init(witType: 0)
        self.freeView.frame = CGRectMake(0, 0, TDScreenWidth, TDScreenHeight)
        
        self.freeView.cancelButtonHandle = { (AnyObject) -> () in
            self.removeFreeView()
        }
        
        self.freeView.sureButtonHandle = { (AnyObject) -> () in
            self.removeFreeView()
            self.freeExperienceAction()
        }
        UIApplication.sharedApplication().keyWindow?.rootViewController?.view.addSubview(self.freeView)
    }
    
    func removeFreeView() {
        self.freeView.endEditing(true)
        self.freeView.removeFromSuperview()
    }
    
    func freeExperienceAction() { //加入指定课程到试听课
        
        self.courseDetailView.activityView.startAnimating()
        
        let requestModel = TDRequestBaseModel.init()
        requestModel.getMyFreeCourseDetail(session.currentUser?.username, courseID: self.courseID, onViewController:self)
        
        requestModel.addFreeCourseHandle = {(array) -> () in
            let enrolArray : NSArray = array
            
            if enrolArray.count > 0 {
                let enrolModel = enrolArray[0]
                self.coursesTableChoseCourse(enrolModel as! UserCourseEnrollment)
                
                if self.courseModel.course_status == 1 && self.getFree != 1 { //未购买未试听 && 没点过试听按钮
                    self.setFreeBttuonText("\(30 * 60)") //30分钟
                }

                self.gotoStudyView = 1
                self.getFree = 1
                
            } else {
                preconditionFailure("course without a course Array")
            }
            
            self.courseDetailView.activityView.stopAnimating()
            
            print("加入试听课程 -- \(array)")
        }
        
        requestModel.showMsgHandle = {(msgStr) in
            //            self.freeCourseFinishTime()
            self.courseDetailView.makeToast(msgStr, duration: 1.08, position: CSToastPositionCenter)
            self.courseDetailView.activityView.stopAnimating()
        }
        
        requestModel.addFreeCourseFailed = { () in//加入失败，重新登录
            self.courseDetailView.activityView.stopAnimating()
            
            let alertView = UIAlertView.init(title: Strings.systemWaring, message: Strings.loginOverDue, delegate: self, cancelButtonTitle: Strings.ok)
            alertView.show()
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        self.logoutCurrentUser()
    }
    
    func logoutCurrentUser() {
        OEXFileUtility.nukeUserPIIData()
        self.environment.router?.logout()
    }
    
    func coursesTableChoseCourse(enrollment: UserCourseEnrollment) { //跳转到试听课的商务统计
        
        NSUserDefaults.standardUserDefaults().setValue("Come_From_Course_Detail", forKey: "Come_From_Course_Detail")
        if let course_id = self.courseModel.course_id {
            self.environment.router?.showCourseWithID(course_id, fromController: self, animated: true, whereFrom: 1,enrollment:enrollment)
        } else {
            preconditionFailure("course without a course id")
        }
    }
    
    func setFreeBttuonText(timeStr: String) { //计算时间
        
        let timeNum = Int(timeStr)!
        if timeNum <= 0 {
            freeCourseFinishTime()
        } else {
            setButtonTimeStr(timeNum,type: 0)
            self.timeNum = timeNum
            self.setupFreeTimer()
        }
    }
    
    func setButtonTimeStr(timeNum: Int,type: Int) { // 0 不用刷新，1 刷新
        
        let minute = timeNum / 60
        let second = timeNum % 60
        
        let minuteStr = minute < 10 ? "0\(minute)" : "\(minute)"
        let secondStr = second < 10 ? "0\(second)" : "\(second)"
        self.courseModel.freeStr = "\(Strings.freeTialTime)（\(minuteStr):\(secondStr)）"
        if type == 1 {
            self.courseDetailView.freeButtonStrHandle()
        }
        
        if timeNum >= 0 {
            NSUserDefaults.standardUserDefaults().setValue("\(timeNum)", forKey: "Free_Course_Free_Time")
        }
    }
    
    private func setupFreeTimer() {
        
        if freeTimer != nil {
            setNilTimer()
        }
        
        freeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(freeCourseTimeChange), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(freeTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func freeCourseTimeChange() {
        
        self.timeNum -= 1
        setButtonTimeStr(self.timeNum,type: 1)
        
        print("======>>> \(self.timeNum)")
        
        if self.timeNum > 0 {
           return
        }
        
        freeCourseFinishTime()
        setNilTimer()
        
        if self.gotoStudyView == 1 {
            freeCourseFinishFreeview()
        }
    }
    
    func setNilTimer() {
        freeTimer?.invalidate()
        freeTimer = nil
    }
    
    func freeCourseFinishTime() {
        freeCourseEndedStr()
        self.courseDetailView.freeButtonStrHandle()
    }
    
    func freeCourseEndedStr() {
        freeFinish = 1
        self.courseModel.freeStr = Strings.freeCourseEnded
    }
    
    func appEnterForeground() { //app进入前台，重新计算时间
        
        self.timeNum = Int(self.baseTool.getFreeCourseSecond("Free_Course_Date_Str"))
        
        let retquestModel = TDRequestBaseModel.init()
        retquestModel.getMyFreeCourseDetail(self.username, courseID: self.courseID)
        retquestModel.getDetailHandle = { () in
            
            let timeStr = NSUserDefaults.standardUserDefaults().valueForKey("Free_Course_Free_Time") as! String
            let numInt = Int(timeStr)
            if numInt >= 0 {
                self.timeNum = numInt!
            }
        }
    }
    
    /* 试听结束弹框  */
    func freeCourseFinishFreeview() {//试听课程结束
        NSUserDefaults.standardUserDefaults().setValue("0", forKey: "Free_Course_Free_Time")
        
        let baseTool = TDBaseToolModel.init()
        baseTool.interfaceOrientation(.Portrait)
        
        self.freeView = TDFreeAlertView.init(witType: 1)
        self.freeView.frame = CGRectMake(0, 0, TDScreenWidth, TDScreenHeight)
        
        self.freeView.cancelButtonHandle = { (AnyObject) -> () in
            
            self.freeView.removeFromSuperview()
            self.navigationController?.popToViewController((self.navigationController?.childViewControllers[1])!, animated: true)
        }
        
        self.freeView.sureButtonHandle = { (AnyObject) -> () in
            
            if self.courseModel.submitType == 2 {
                self.gotoWaitForPayVc()
                
            } else {
                self.gotoChooseCourseVC()
            }
            self.freeView.removeFromSuperview()
        }
        UIApplication.sharedApplication().keyWindow?.rootViewController?.view.addSubview(self.freeView)
    }
    
    
    func gotoChooseCourseVC() {
        let courseId = NSUserDefaults.standardUserDefaults().valueForKey("Free_Course_CourseID")
        let chooseCourseVC = TDChooseCourseViewController.init()
        chooseCourseVC.username = self.username
        chooseCourseVC.courseID = "\(courseId!)"
        chooseCourseVC.whereFrom = 1
        self.navigationController?.pushViewController(chooseCourseVC, animated: true)
    }
    
    //MARK:  ----->>> UI <<<------

    func setViewConstraint() {
        self.view.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        
        courseDetailView.showAllTextHandle = { showAll in
            self.showAllText = showAll
//            self.courseDetailView.tableView.reloadData()
            let indexpath = NSIndexPath.init(forRow: 0, inSection: 0)
            self.courseDetailView.tableView.reloadRowsAtIndexPaths([indexpath], withRowAnimation: .Fade)
        }
        
        /* 加入课程按钮 */
        courseDetailView.submitButtonHandle = { () in
            
            let currentUser = self.session.currentUser //登录状态
            if currentUser != nil {
                self.gotoStudyView = 2
                self.addCourseButtonHandle()
                
            } else {
                
                self.view.makeToast(Strings.loginBeforeEnroll, duration: 0.5, position: CSToastPositionCenter)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                   self.logoutCurrentUser()//到登录界面
                })
            }
        }
        
        /* 试听按钮 */
        courseDetailView.auditionButtonHandle = { () in
            
            self.courseDetailView.activityView.stopAnimating()
            self.addAuditionButtonHandle()
        }
        
        courseDetailView.playButtonHandle = { () in
            self.gotoStudyView = 2
            self.playVideoAction()
        }
        
        courseDetailView.tableView.delegate = self
        self.view.addSubview(courseDetailView)
        courseDetailView.snp_makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(self.view)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
