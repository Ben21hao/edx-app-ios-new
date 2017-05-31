//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class DiscussionTopicsViewController: OfflineSupportViewController, UITableViewDataSource, UITableViewDelegate, InterfaceOrientationOverriding,UIGestureRecognizerDelegate  {
    
    public typealias Environment = protocol<DataManagerProvider, OEXRouterProvider, OEXAnalyticsProvider, ReachabilityProvider>
    
    private enum TableSection : Int {
        case AllPosts
        case Following
        case CourseTopics
    }
    
    private let topics = BackedStream<[DiscussionTopic]>()
    private let environment: Environment
    private let courseID : String
    
    private let searchBar = UISearchBar()
    private var searchBarDelegate : DiscussionSearchBarDelegate?
    private let loadController : LoadStateViewController
    
    private let contentView = UIView()
    private let tableView = UITableView()
    private let separatorLine = UIView()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.loadController = LoadStateViewController()
        
       super.init(env: environment)
        
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        
//        tableView.estimatedRowHeight = 80.0
//        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: CGRectZero)
}
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        
        let leftButton = UIButton.init(frame: CGRectMake(0, 0, 48, 48))
        leftButton.setImage(UIImage.init(named: "backImagee"), forState: .Normal)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23)
        leftButton.addTarget(self, action: #selector(leftBarItemAction), forControlEvents: .TouchUpInside)
        
        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let leftBarItem = UIBarButtonItem.init(customView: leftButton)
        self.navigationItem.leftBarButtonItem = leftBarItem

        self.titleViewLabel.text = Strings.discussionTopics
   
        self.separatorLine.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        
        contentView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.view.addSubview(contentView)
        
        self.contentView.addSubview(tableView)
        self.contentView.addSubview(searchBar)
        self.contentView.addSubview(separatorLine)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        searchBar.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
        
        searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
            if let owner = self {
                owner.environment.router?.showPostsFromController(owner, courseID: owner.courseID, queryString : text)
            }
        }
        searchBar.delegate = searchBarDelegate
        
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        searchBar.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(48);
        }
        
        separatorLine.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(searchBar.snp_bottom)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.top.equalTo(separatorLine)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicCell.classForCoder(), forCellReuseIdentifier: DiscussionTopicCell.identifier)
        
        loadController.setupInController(self, contentView: contentView)
        loadTopics()
    }
    
    func leftBarItemAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    private func loadTopics() {
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            })
    }
    
    private func refreshTopics() {
        loadController.state = .Initial
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        loadTopics()
    }
    
    func loadedData() {
        self.loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .NoTopics, message : Strings.unableToLoadCourseContent) : .Loaded
        self.tableView.reloadData()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        self.environment.analytics.trackScreenWithName(OEXAnalyticsScreenViewTopics, courseID: self.courseID, value: nil)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func reloadViewData() {
        refreshTopics()
    }
    
    override public func shouldAutorotate() -> Bool {
        return true
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    // MARK: - TableView Data and Delegate
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case TableSection.AllPosts.rawValue:
            return 1
        case TableSection.Following.rawValue:
            return 1
        case TableSection.CourseTopics.rawValue:
            return self.topics.value?.count ?? 0
        default:
            return 0
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        tableView.separatorColor = OEXStyles.sharedStyles().baseColor6()
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionTopicCell.identifier, forIndexPath: indexPath) as! DiscussionTopicCell
        
        var topic : DiscussionTopic? = nil
        
        switch (indexPath.section) {
        case TableSection.AllPosts.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.allPosts, children: [DiscussionTopic](), depth: 0, icon:nil)
        case TableSection.Following.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.postsImFollowing, children: [DiscussionTopic](), depth: 0, icon: Icon.FollowStar)
        case TableSection.CourseTopics.rawValue:
            if let discussionTopic = self.topics.value?[indexPath.row] {
                topic = discussionTopic
            }
        default:
            assert(true, "Unknown section type.")
        }
        
        if let discussionTopic = topic {
            cell.topic = discussionTopic
        }
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        
        switch (indexPath.section) {
        case TableSection.AllPosts.rawValue:
            environment.router?.showAllPostsFromController(self, courseID: courseID, followedOnly: false)
            
        case TableSection.Following.rawValue:
            environment.router?.showAllPostsFromController(self, courseID: courseID, followedOnly: true)
            
        case TableSection.CourseTopics.rawValue:
            if let topic = self.topics.value?[indexPath.row] {
                    environment.router?.showPostsFromController(self, courseID: courseID, topic: topic)
            }
        default: ()
        }
    }
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 48;
    }
}

extension DiscussionTopicsViewController {
    public func t_topicsLoaded() -> Stream<[DiscussionTopic]> {
        return topics
    }
}

