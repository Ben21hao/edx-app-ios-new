//
//  CourseHandoutsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 26/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
public class CourseHandoutsViewController: OfflineSupportViewController, UIWebViewDelegate,UIGestureRecognizerDelegate {
    
    public typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, ReachabilityProvider>

    let courseID : String
    let environment : Environment
    let webView : UIWebView
    let loadController : LoadStateViewController
    let handouts : BackedStream<String> = BackedStream()
    private var whereFrom = 0
    private var enrollment: UserCourseEnrollment?
    
    private var titleL : UILabel? //自定义标题
    init(environment : Environment, courseID : String, whereFrom: Int, enrollment: UserCourseEnrollment?) {
        self.environment = environment
        self.courseID = courseID
        self.webView = UIWebView()
        self.loadController = LoadStateViewController()
        
        super.init(env: environment)
        
        self.whereFrom = whereFrom
        self.enrollment = enrollment;
        
        if self.whereFrom == 1 {
            getFreeCourseHandout()
        } else {
            addListener()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        loadController.setupInController(self, contentView: webView)
        setViewConstraint()
        setNavigationStyles()
    
        loadHandouts()
    }
    
    override func reloadViewData() {
        loadHandouts()
    }
    
    private func setViewConstraint() {
        webView.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        webView.delegate = self
        view.addSubview(webView)
        
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }

    private func setNavigationStyles() {
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.titleL = UILabel(frame:CGRect(x:0, y:0, width:40, height:40))
        self.titleL?.text = Strings.courseHandouts
        self.navigationItem.titleView = self.titleL
        self.titleL?.font = UIFont(name:"OpenSans",size:18.0)
        self.titleL?.textColor = UIColor.whiteColor()
        
        let leftButton = UIButton.init(frame: CGRectMake(0, 0, 48, 48))
        leftButton.setImage(UIImage.init(named: "backImagee"), forState: .Normal)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23)
        leftButton.addTarget(self, action: #selector(leftBarItemAction), forControlEvents: .TouchUpInside)
        
        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let leftBarItem = UIBarButtonItem.init(customView: leftButton)
        self.navigationItem.leftBarButtonItem = leftBarItem
    }
    
    func leftBarItemAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func streamForCourse(course : OEXCourse) -> Stream<String>? {
        if let access = course.courseware_access where !access.has_access {
            return Stream<String>(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info))
            
        } else {
            let request = CourseInfoAPI.getHandoutsForCourseWithID(courseID, overrideURL: course.course_handouts)
            let loader = self.environment.networkManager.streamForRequest(request, persistResponse: true)
            return loader
        }
    }

    private func loadHandouts() {
        if !handouts.active {
            loadController.state = .Initial
            let courseStream = self.environment.dataManager.enrollmentManager.streamForCourseWithID(courseID)
            let handoutStream = courseStream.transform {[weak self] enrollment in
                return self?.streamForCourse(enrollment.course) ?? Stream<String>(error : NSError.oex_courseContentLoadError())
            }
            self.handouts.backWithStream(handoutStream)
        }
    }
    
    private func addListener() {
        handouts.listen(self, success: { [weak self] courseHandouts in
            if let
                displayHTML = OEXStyles.sharedStyles().styleHTMLContent(courseHandouts, stylesheet: "handouts-announcements"),
                apiHostUrl = OEXConfig.sharedConfig().apiHostURL()
            {
                self?.webView.loadHTMLString(displayHTML, baseURL: apiHostUrl)
                self?.loadController.state = .Loaded
            } else {
                self?.loadController.state = LoadState.failed()
            }
            
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            })
    }
    
    func getFreeCourseHandout() {
        
        let requestModel = TDRequestBaseModel.init()
        requestModel.getCourseHandout(self.courseID, withHandoutUrl: self.enrollment?.course.course_handouts)
        
        requestModel.getCourseHandoutHandle = {(htmlStr) -> () in
            if htmlStr.characters.count == 0 {
                self.loadController.state = .Loaded
                self.webView.makeToast("暂无资料", duration: 1.08, position: CSToastPositionCenter)
            } else {
                let displayHTML = OEXStyles.sharedStyles().styleHTMLContent(htmlStr, stylesheet: "handouts-announcements")
                let apiHostUrl = OEXConfig.sharedConfig().apiHostURL()
                self.webView.loadHTMLString(displayHTML!, baseURL: apiHostUrl)
            }
        }
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right: 0)
        super.updateViewConstraints()
    }
    
    //MARK: UIWebView delegate
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.Other) {
            if let URL = request.URL {
                 UIApplication.sharedApplication().openURL(URL)
                return false
            }
        }
        return true
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        self.loadController.state = LoadState.failed()
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        self.loadController.state = .Loaded
    }
}
