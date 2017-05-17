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
    
    var courseModel: OEXCourse
    private let courseID: String
    private let courseName : String
    private let companyID : String
    private let username : String
    
    private lazy var loadController = LoadStateViewController()
    
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
        
        let currentUser = self.session.currentUser //登陆状态
        if currentUser == nil {
            NSNotificationCenter.defaultCenter().postNotificationName("OEXSessionEndedNotification", object: nil)
        }
        
        self.titleViewLabel.text = self.courseName
        self.setViewConstraint()
        
        self.loadController.setupInController(self, contentView: courseDetailView)
        
        if self.username != "" {
            self.getData()
        }
        
        self.listenData()
        self.loadCourseMessage()
    }
    
    private func listenData() { //数据
        self.courseStream.listen(self, success: {[weak self] (course, enrolled) in
            
            self!.courseModel = course
            print(" 时间 ----> \(self?.courseModel.start_display_info.displayDate) --> \(self?.courseModel.start_display_info.date)")
            
            if enrolled { //已报名
                self?.courseModel.submitType = 0//查看课程
                
            } else { //未报名
                let now = NSDate()
                if now.isEarlierThanOrEqualTo(self?.courseModel.start_display_info.date) {
                    self?.courseModel.submitType = 3//即将开课
                    
                } else {
                    if self?.prepareOrder == true {
                        self?.courseModel.submitType = 2//查看待支付
                    } else {
                        self?.courseModel.submitType = 1//立即加入
                    }
                }
            }
            
            self?.courseDetailView.applyCourse(course)//渲染显示数据
            self?.loadController.state = .Loaded
            
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        
        self.courseDetailView.loaded.listen(self) {[weak self] _ in
            self?.loadController.state = .Loaded
        }
    }
    
    func getData() -> Void {
        let path = "\(ELITEU_URL)/api/courses/v1/get_wait_order_list/?username=\(self.username)"
        let url:NSURL = NSURL(string: path)!
        
        let request : NSMutableURLRequest = NSMutableURLRequest(URL: url)
        let session : NSURLSession = NSURLSession.sharedSession()
        let dataTask : NSURLSessionDataTask = session.dataTaskWithRequest(request) { (data, respone, error) in
            
            if(error == nil) {
                
                var dict : NSDictionary? = nil
                do {
                    dict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) as?NSDictionary
                } catch {
                    
                }
                print("+++++++++++++++++++++++%@+++++++++++++",dict)
                
                if let dataArrary = dict!["data"] as? NSArray {
                    for i in 0..<dataArrary.count {
                        if  let dataDic = dataArrary[i] as? NSDictionary {
                            if let subDataArray = dataDic["order_items"] as? NSArray {
                                for j in 0 ..< subDataArray.count  {
                                    if let subDataDic = subDataArray[j] as? NSDictionary {
                                        if let courseId = subDataDic["course_id"] as? NSString {
                                            if self.courseID == courseId {
                                                self.prepareOrder = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        dataTask.resume()
    }

    private func loadCourseMessage() { //获取课程信息
        
        let request = CourseCatalogAPI.getCourse(courseID)
        let courseStream = environment.networkManager.streamForRequest(request)
        let enrolledStream = environment.dataManager.enrollmentManager.streamForCourseWithID(courseID).resultMap {
            return .Success($0.isSuccess)
        }
        let stream = joinStreams(courseStream, enrolledStream).map{($0, enrolled: $1) }
        self.courseStream.backWithStream(stream)
    }
    
    
    //MARK: tableview Delegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                
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
                let size = getSizeForString(introduceStr)
                
                if self.courseModel.moreDescription?.characters.count == 0 && self.courseModel.short_description?.characters.count == 0 {
                    return 0
                }
                return size.height + 48
                
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
        let vc = OutlineViewController()
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
        let userCouponVC = WaitForPayViewController()
        userCouponVC.username = self.username //传当前用户名
        self.navigationController?.pushViewController(userCouponVC, animated: true)
    }
    
    func gotoChooseCourseVc() { //选择课表
        
        //        if self.courseModel.is_eliteu_course == true {//英荔课程
        
            let vc = TDChooseCourseViewController();
            vc.username = self.username
            vc.courseID = self.courseID
            self.navigationController?.pushViewController(vc, animated: true)
        
        //        } else {
        //            addOwnCompanyCourseHandle()
        //        }
        
    }
    
    func logoutCurrentUser() {
        OEXFileUtility.nukeUserPIIData()
        self.environment.router?.logout()
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
        manager.addOwnCompanyCourseHandle = { () in
            self.environment.router?.showMyCourses()
        }
    }
    
    //MARK: UI
    func setViewConstraint() {
        self.view.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        
        courseDetailView.showAllTextHandle = { showAll in
            self.showAllText = showAll
            self.courseDetailView.tableView.reloadData()
        }
        courseDetailView.submitButtonHandle = { () in
            
            let currentUser = self.session.currentUser //登陆状态
            if currentUser != nil {
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
            } else {
                self.logoutCurrentUser()//到登陆界面
            }
        }
        
        courseDetailView.auditionButtonHandle = { () in
//            self.courseDetailView.activityView.stopAnimating()
            self.showCourseScreen()
        }
        
        courseDetailView.playButtonHandle = { () in
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
