//
//  CourseCatalogDetailViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/3/15.
//  Copyright © 2015 edX. All rights reserved.
//

import WebKit
import UIKit
import edXCore


class CourseCatalogDetailViewController: UIViewController,UIScrollViewDelegate,UIGestureRecognizerDelegate {
    
    private let courseID: String
    private let coursePrice : Double
    private let courseName : String

    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider, OEXRouterProvider>
    
    private let environment: Environment
    private lazy var loadController = LoadStateViewController()

    private var h1 : CGFloat = 0
    private var h2 : CGFloat = 0
    var tag = 1
    let session = OEXRouter.sharedRouter().environment.session
    var course: OEXCourse
    private lazy var aboutView : CourseCatalogDetailView = {//UI
        return CourseCatalogDetailView(frame: CGRectZero, environment: self.environment)
    }()
    
    private let courseStream = BackedStream<(OEXCourse, enrolled: Bool)>()
    
    private var titleL : UILabel?  //自定义标题
    init(environment : Environment, courseModel : OEXCourse) {
        
        self.courseID = courseModel.course_id!
        self.coursePrice = (courseModel.course_price?.doubleValue)!
        self.courseName = courseModel.name!
        self.environment = environment
        course = OEXCourse()
        super.init(nibName: nil, bundle: nil)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialView()
    
        let leftButton = UIButton.init(frame: CGRectMake(0, 0, 48, 48))
        leftButton.setImage(UIImage.init(named: "backImagee"), forState: .Normal)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23)
        leftButton.addTarget(self, action: #selector(leftBarItemAction), forControlEvents: .TouchUpInside)
        
        self.navigationController?.interactivePopGestureRecognizer!.enabled = true
        self.navigationController?.interactivePopGestureRecognizer!.delegate = self
        
        let leftBarItem = UIBarButtonItem.init(customView: leftButton)
        self.navigationItem.leftBarButtonItem = leftBarItem
        
        //添加标题文本
        self.titleL = UILabel(frame:CGRect(x:0, y:0, width:40, height:40))
        self.titleL?.text = self.courseName;
        self.titleL?.font = UIFont(name:"OpenSans",size:18.0)
        self.titleL?.textColor = UIColor.whiteColor()
        self.navigationItem.titleView = titleL
        
        listen()
        loadCourseMessage()
        addGesAction()//添加手势
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func initialView() {
        
        view.addSubview(aboutView)
        self.aboutView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.loadController.setupInController(self, contentView: aboutView)
        self.aboutView.moreBtn.addTarget(self, action: #selector(setMoreBtn), forControlEvents: UIControlEvents.TouchUpInside)
        self.aboutView.playButton.addTarget(self, action: #selector(playVideoAction), forControlEvents: UIControlEvents.TouchUpInside)
        
        let str1 = Strings.enrollMessage
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.lineSpacing = 2
        let size = str1.boundingRectWithSize(CGSizeMake(TDScreenWidth - 180, TDScreenHeight), options:[.UsesLineFragmentOrigin, .UsesFontLeading] , attributes: [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 12)! , NSParagraphStyleAttributeName : paragraph], context: nil).size
        
        let y : CGFloat = 909 + size.height
        self.aboutView.myScrollV.contentSize = CGSizeMake(UIScreen.mainScreen().bounds.width, y + 20)
        self.aboutView.myScrollV.delegate = self
        self.aboutView.myScrollV.bounces = true
        self.aboutView.myScrollV.scrollEnabled = true
        self.aboutView.myScrollV.showsVerticalScrollIndicator = true
    }
    
    func leftBarItemAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func addGesAction() { //添加手势
        
        let gesture1 = UITapGestureRecognizer(target: self, action: #selector(CourseCatalogDetailViewController.viewTap1))
        self.aboutView.secondCell.addGestureRecognizer(gesture1)
        
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(CourseCatalogDetailViewController.viewTap2))
        self.aboutView.thirdCell.addGestureRecognizer(gesture2)
        
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(CourseCatalogDetailViewController.viewTap3))
        self.aboutView.fourthCell.addGestureRecognizer(gesture3)
        
        let gesture4 = UITapGestureRecognizer(target: self, action: #selector(CourseCatalogDetailViewController.viewTap4))
        self.aboutView.fivethCell.addGestureRecognizer(gesture4)
        
        let gesture5 = UITapGestureRecognizer(target: self, action: #selector(CourseCatalogDetailViewController.viewTap5))
        self.aboutView.sixthCell.addGestureRecognizer(gesture5)
        
        self.aboutView.actionButton.addTarget(self, action: #selector(lookForCourse), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func lookForCourse() { //加入课程按钮
        if  tag == 3 {
//            self.view.makeToast("即将开课，请耐心等候", duration: 1.09, position: CSToastPositionCenter)
        }
        if tag == 2 { //待支付
            let userCouponVC1 = WaitForPayViewController()
            userCouponVC1.username = session.currentUser?.username //传当前用户名
            self.navigationController?.pushViewController(userCouponVC1, animated: true)
        }
        if tag == 1 { //选课表
            let vc = TDChooseCourseViewController();
            vc.username = session.currentUser?.username
            vc.courseID = self.courseID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    internal func viewTap1() { //主讲教授
        let vc = TDProfessorViewController()
        vc.professorName = self.aboutView.professor
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    internal func viewTap2() { //课程大纲
        let vc = OutlineViewController()
        vc.courseID = self.courseID
        self.navigationController?.pushViewController(vc, animated: true)
    }
    internal func viewTap3() { //学员评价 
        let vc = TDCommentViewController()
        vc.courseID = self.courseID
        let currentUser = session.currentUser?.username//传当前用户名
        vc.userName = currentUser;
        self.navigationController?.pushViewController(vc, animated: true)
    }
    internal func viewTap4() { //班级
        let vc = QRViewController();
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    internal func viewTap5() { //助教
        let vc = TDOrderAssistantViewController();
        vc.whereFrom = 2
        vc.courseId = self.courseID
        vc.myName = session.currentUser?.username
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func setMoreBtn() { //展开全文
        var y1 = self.aboutView.bottomV.frame.maxY
        
        if self.aboutView.moreLabel.hidden == true { //隐藏下部文字
            self.aboutView.moreBtn.setTitle(Strings.allText, forState: UIControlState.Normal)
            y1 -= h2
            self.aboutView.myScrollV.contentSize = CGSizeMake(UIScreen.mainScreen().bounds.width, y1 + 20)
            
        } else { //显示下部文字
            self.aboutView.moreBtn.setTitle(Strings.stopUp, forState: UIControlState.Normal)
            h1 = self.aboutView.blurbLabel.bounds.height
            h2 = self.aboutView.moreLabel.bounds.height
            y1 += h2
            self.aboutView.myScrollV.contentSize = CGSizeMake(UIScreen.mainScreen().bounds.width, y1 + 20)
        }
    }
    
    func playVideoAction() { //播放预告
        
        let videoVc = TDVideoPlayerViewController()
        videoVc.url = self.course.intro_video_3rd_url;
        videoVc.courseName = self.courseName;
        self.navigationController?.pushViewController(videoVc, animated: true)
    }
    
    private func listen() { //数据
        self.courseStream.listen(self,
            success: {[weak self] (course, enrolled) in
                
                self!.course = course
                self?.aboutView.applyCourse(course)//渲染显示数据
                print(" 时间 ----> \(self?.course.start_display_info.displayDate) --> \(self?.course.start_display_info.date)")
                
                if enrolled { //已报名
                    self?.aboutView.actionText = Strings.CourseDetail.viewCourse//查看课程
                    self?.aboutView.action = {completion in
                        self?.showCourseScreen()
                        completion()
                    }
                    
                } else { //未报名
                    let now = NSDate()
                    if now.isEarlierThanOrEqualTo(self?.course.start_display_info.date) { //
                        self?.aboutView.actionText = Strings.willBeginCourse
                        self?.aboutView.action = {[weak self] completion in
                            self?.tag = 3
                            completion()
                        }
                        
                    } else {
                        let baseTool = TDBaseToolModel.init()
                        let priceStr = baseTool.setDetailString(Strings.CourseDetail.enrollNow + "￥" + String(format: "%.2f",(self?.coursePrice)!), withFont: 16, withColorStr: "#ffffff")
                        self?.aboutView.actionAttributeText = priceStr //马上加入
                        self?.aboutView.action = {[weak self] completion in
                            self?.enrollInCourse(completion)
                        }
                        let username = self!.session.currentUser?.username ?? ""
                        if username != "" {
                            self!.getData()
                        }
                    }
                }
                
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        
        self.aboutView.loaded.listen(self) {[weak self] _ in
            self?.loadController.state = .Loaded
        }
    }
    
    func getData() -> Void {
        let domain = ELITEU_URL
        let username = OEXRouter.sharedRouter().environment.session.currentUser?.username
        let link = "/api/courses/v1/get_wait_order_list/?username="
        let path = domain + link + username!
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
                                                self.tag = 2
                                                let baseTool = TDBaseToolModel.init()
                                                let priceStr = baseTool.setDetailString(Strings.viewPrepareOrder, withFont: 16, withColorStr: "#ffffff")
                                                self.aboutView.actionAttributeText = priceStr //查看待支付
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
    
    private func showCourseScreen(message message: String? = nil) {
        self.environment.router?.showMyCourses(animated: true, pushingCourseWithID:courseID) //跳到商务统计
        
        if let message = message {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(EnrollmentShared.overlayMessageDelay * NSTimeInterval(NSEC_PER_SEC)))
            dispatch_after(after, dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotificationName(EnrollmentShared.successNotification, object: message, userInfo: nil)
            }
        }
    }
    
    private func enrollInCourse(completion : () -> Void) {
        
        let notEnrolled = environment.dataManager.enrollmentManager.enrolledCourseWithID(self.courseID) == nil
        
        guard notEnrolled else {
            self.showCourseScreen(message: Strings.findCoursesAlreadyEnrolledMessage)
            completion()
            return
        }
        
        let courseID = self.courseID
        let request = CourseCatalogAPI.enroll(courseID) //身份验证
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                self?.environment.analytics.trackUserEnrolledInCourse(courseID)
                self?.showCourseScreen(message: Strings.findCoursesEnrollmentSuccessfulMessage)
            } else {
//                self?.showOverlayMessage(Strings.findCoursesEnrollmentErrorDescription) //移动端无法加入课程
            }
            completion()
        }
    }
    
}
// Testing only
extension CourseCatalogDetailViewController {
    
    var t_loaded : Stream<()> {
        return self.aboutView.loaded
    }
    
    var t_actionText: String? {
        return self.aboutView.actionText
    }
    
    func t_enrollInCourse(completion : () -> Void) {
        enrollInCourse(completion)
    }
    
}
