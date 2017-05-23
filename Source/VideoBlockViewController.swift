//
//  VideoBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding, VideoTranscriptDelegate, RatingViewControllerDelegate {
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, ReachabilityProvider, OEXConfigProvider, OEXRouterProvider>

    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let loader = BackedStream<CourseBlock>()
    
        let loadController : LoadStateViewController
    let videoController : OEXVideoPlayerInterface
    let videoPlayerVC : TDVideoUrlPlayController//用来播放url的
    var isUrlVideo = false
    
    var rotateDeviceMessageView : IconMessageView?
    var videoTranscriptView : VideoTranscript?
    var subtitleTimer = NSTimer()
    var contentView : UIView?

    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        videoController = OEXVideoPlayerInterface()
        loadController = LoadStateViewController()
        videoPlayerVC = TDVideoUrlPlayController()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMoveToParentViewController(self)
        videoController.delegate = self
        
        addLoadListener()//获取数据
    }
    
    var courseID : String {
        return courseQuerier.courseID
    }
    
    required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLoadListener() {
        loader.listen (self,
                       success : { [weak self] block in
                        if let video = block.type.asVideo where video.isYoutubeVideo,
                            let url = block.blockURL
                        {
                            self?.showYoutubeMessage(url)
                        }
                        else if
                            let video = self?.environment.interface?.stateForVideoWithID(self?.blockID, courseID : self?.courseID)
                            where block.type.asVideo?.preferredEncoding != nil
                        {
                            self?.showLoadedBlock(block, forVideo: video)
                        }
                        else if let video = block.type.asVideo {
                            self?.isUrlVideo = true
                            self?.openVideoUrl(video.videoURL!)
                            
                        }
                        else {
                            //                            print("------>>>>>>>>>>>> \(block.displayName) -- \(block.type.asVideo?.videoURL)")
                            self?.showError(nil)
                        }
            }, failure : {[weak self] error in
                self?.showError(error)
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = UIView(frame: CGRectZero)
        view.addSubview(contentView!)
        
        loadController.setupInController(self, contentView : contentView!)
        
        videoController.view.translatesAutoresizingMaskIntoConstraints = false
        videoController.fadeInOnLoad = false
        contentView?.addSubview(videoController.view)
        
        rotateDeviceMessageView = IconMessageView(icon: .RotateDevice, message: Strings.rotateDevice)//旋转屏幕
        contentView?.addSubview(rotateDeviceMessageView!)
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.videoController.moviePlayerController?.controls?.hideOptionsAndValues()
        }
        rotateDeviceMessageView?.addGestureRecognizer(tapGesture)
        
        if environment.config.isVideoTranscriptEnabled {
            videoTranscriptView = VideoTranscript(environment: environment)
            videoTranscriptView?.delegate = self
            contentView?.addSubview(videoTranscriptView!.transcriptTableView)
        }
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: UIAccessibilityVoiceOverStatusChanged) { (_, observer, _) in
            observer.setAccessibility()
        }
    }
    
    func setAccessibility() {
        if let ratingController = self.presentedViewController as? RatingViewController where UIAccessibilityIsVoiceOverRunning() {
            // If Timely App Reviews popup is showing then set popup elements as accessibilityElements
            view.accessibilityElements = [ratingController.ratingContainerView.subviews]
            setParentAccessibility(ratingController)
        }
        else {
            view.accessibilityElements = [view.subviews]
            setParentAccessibility()
        }
    }
    
    func setParentAccessibility(ratingController: RatingViewController? = nil) {
        if let parentController = self.parentViewController as? CourseContentPageViewController {
            if let ratingController = ratingController {
                parentController.setAccessibility(ratingController.ratingContainerView.subviews, isShowingRating: true)
            }
            else {
                parentController.setAccessibility(parentController.view.subviews)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewDidAppear(animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        validateSubtitleTimer()
        
        if !canDownloadVideo() {
            guard let video = self.environment.interface?.stateForVideoWithID(self.blockID, courseID : self.courseID) where video.downloadState == .Complete else {
                self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
        }
        
        guard let videoPlayer = videoController.moviePlayerController else { return }
        if currentOrientation() == .LandscapeLeft || currentOrientation() == .LandscapeRight {
            videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        videoController.setAutoPlaying(false)
        self.subtitleTimer.invalidate()
    }
    
    private func loadVideoIfNecessary() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        
        if  self.isVerticallyCompact() {
            applyLandscapeConstraints()
        }
        else{
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {//竖直
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if isUrlVideo == false {
            videoController.height = view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO)
            videoController.width = view.bounds.size.width
            
            videoController.view.snp_remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                
                make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
            }
            
            setRotateViewCostraint(videoController)
            
        } else {
            //            NSNotificationCenter.defaultCenter().postNotificationName("VideoView_InterFace_Orientation_Potraint", object: nil)
            self.navigationController?.setToolbarHidden(false, animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            videoPlayerVC.hideStatusBar = false
            videoPlayerVC.barView.fullScreenButton.selected = false
            
            videoPlayerVC.view.snp_remakeConstraints{ (make) in
                make.left.right.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                } else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
            }
            
            setRotateViewCostraint(videoPlayerVC)
        }
    }
    
    func setRotateViewCostraint(topViewController: UIViewController) {
        
        rotateDeviceMessageView?.snp_remakeConstraints {make in
            make.top.equalTo(topViewController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            // There's a weird OS bug where the bottom layout guide doesn't get set properly until
            // the layout cycle after viewDidAppear, so use the parent in the mean time
            if #available(iOS 9, *) {
                make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
            } else {
                make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
            }
        }
        
        videoTranscriptView?.transcriptTableView.snp_remakeConstraints { make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(view.snp_bottom).offset(-barHeight)
        }
    }

    
    private func applyLandscapeConstraints() {//横屏
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        if isUrlVideo == false {
            let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
            
            videoController.height = playerHeight
            videoController.width = view.bounds.size.width
            
            videoController.view.snp_remakeConstraints {make in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                }
                else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                
                make.height.equalTo(playerHeight)
            }
            
//            rotateDeviceMessageView?.snp_remakeConstraints {make in
//                make.height.equalTo(0.0)
//            }
            setPotraitViewCostraint(videoController)
            
        } else {
            //            NSNotificationCenter.defaultCenter().postNotificationName("VideoView_InterFace_Orientation_Lands", object: nil)
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            
            videoPlayerVC.hideStatusBar = true
            videoPlayerVC.barView.fullScreenButton.selected = true
            videoPlayerVC.view.snp_remakeConstraints{ (make) in
                make.leading.equalTo(contentView!)
                make.trailing.equalTo(contentView!)
                if #available(iOS 9, *) {
                    make.top.equalTo(self.topLayoutGuide.bottomAnchor)
                } else {
                    make.top.equalTo(self.snp_topLayoutGuideBottom)
                }
                make.height.equalTo(TDScreenWidth)
            }
            setPotraitViewCostraint(videoPlayerVC)
        }
    }

    func setPotraitViewCostraint(topViewController: UIViewController) {
        
        rotateDeviceMessageView?.snp_remakeConstraints {make in
            make.top.equalTo(topViewController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.height.equalTo(0.0)
        }
    }

    
    func movieTimedOut() {
        if let controller = videoController.moviePlayerController where controller.fullscreen {
            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            self.showOverlayMessage(Strings.timeoutCheckInternetConnection)
        }
    }
    
    private func showError(error : NSError?) {
        loadController.state = LoadState.failed(error, icon: .UnknownError, message: Strings.videoContentNotAvailable)
    }
    
    private func showYoutubeMessage(url: NSURL) {//优酷 -- 通过url播放视频
        let buttonInfo = MessageButtonInfo(title: Strings.Video.viewOnYoutube) {
            if UIApplication.sharedApplication().canOpenURL(url){
                UIApplication.sharedApplication().openURL(url)
            }
        }
        loadController.state = LoadState.empty(icon: .CourseModeVideo, message: Strings.Video.onlyOnYoutube, attributedMessage: nil, accessibilityMessage: nil, buttonInfo: buttonInfo)
    }
    
    func openVideoUrl(urlStr: String) {//用url来播放
        
        addChildViewController(videoPlayerVC)
        videoPlayerVC.didMoveToParentViewController(self)
        videoPlayerVC.url = urlStr
        
        contentView?.addSubview(videoPlayerVC.view)
        videoPlayerVC.view.snp_makeConstraints { (make) in
            make.left.right.equalTo(contentView!)
            if #available(iOS 9, *) {
                make.top.equalTo(self.topLayoutGuide.bottomAnchor)
            } else {
                make.top.equalTo(self.snp_topLayoutGuideBottom)
            }
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
        
        loadController.state = .Loaded
        videoController.view.hidden = true
    }

    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload) {
        navigationItem.title = block.displayName
        
        dispatch_async(dispatch_get_main_queue()) {
            self.loadController.state = .Loaded
        }
        
        videoController.playVideoFor(video)
    }
    
    private func canDownloadVideo() -> Bool {//判断网络是否可下载视频
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return videoController
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return videoController
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        if isUrlVideo == false {
            guard let videoPlayer = videoController.moviePlayerController else { return }
            
            if videoPlayer.fullscreen {
                
                if newCollection.verticalSizeClass == .Regular {
                    videoPlayer.setFullscreen(false, withOrientation: self.currentOrientation())
                }
                else {
                    videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
                }
            }
            else if videoController.shouldRotate && newCollection.verticalSizeClass == .Compact {
                videoPlayer.setFullscreen(true, withOrientation: self.currentOrientation())
                print("ppppppppppppppp")
            }
        }
    }
    
    func validateSubtitleTimer() {
        if !subtitleTimer.valid && videoController.moviePlayerController?.controls != nil {
            subtitleTimer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                                   target: self,
                                                                   selector: #selector(highlightSubtitle),
                                                                   userInfo: nil,
                                                                   repeats: true)
        }
    }
    
    func highlightSubtitle() {
        videoTranscriptView?.highlightSubtitleForTime(videoController.moviePlayerController?.controls?.moviePlayer?.currentPlaybackTime)
    }
    
    //MARK: - OEXVideoPlayerInterfaceDelegate methods
    func videoPlayerTapped(sender: UIGestureRecognizer) {
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !videoPlayer.fullscreen{
            videoPlayer.setFullscreen(true, withOrientation: currentOrientation())
        }
    }
    
    func transcriptLoaded(transcript: [AnyObject]) {
        videoTranscriptView?.updateTranscript(transcript)
        validateSubtitleTimer()
    }
    
    func didFinishVideoPlaying() {
        environment.router?.showAppReviewIfNeeded(self)
    }
    
    //MARK: - VideoTranscriptDelegate methods
    func didSelectSubtitleAtInterval(time: NSTimeInterval) {
        videoController.moviePlayerController?.controls?.setCurrentPlaybackTimeFromTranscript(time)
    }
    
    //MARK: - RatingDelegate
    func didDismissRatingViewController() {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.backBarButtonItem)
    }
}
