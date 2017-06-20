//
//  TDVidoDownloadViewController.m
//  edX
//
//  Created by Ben on 2017/6/12.
//  Copyright © 2017年 edX. All rights reserved.
//

#import "TDVidoDownloadViewController.h"
#import "TDDownloadSubCell.h"

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import "NSArray+OEXSafeAccess.h"

typedef  enum OEXAlertType
{
    OEXAlertTypeNextVideoAlert,
    OEXAlertTypeDeleteConfirmationAlert,
    OEXAlertTypePlayBackErrorAlert,
    OEXAlertTypeCannotPlayVideo,
    OEXAlertTypeVideoTimeOutAlert,
    OEXAlertTypePlayBackContentUnAvailable
}OEXAlertType;

#define RECENT_HEADER_HEIGHT 30.0

@interface TDVidoDownloadViewController () <OEXVideoPlayerInterfaceDelegate,UITableViewDelegate,UITableViewDataSource> {
    NSIndexPath* clickedIndexpath;
}

@property (nonatomic,strong) UIView *video_containerView; //视频页面
@property (nonatomic,strong) UIView *videoVideo; //视频播放页面

@property (nonatomic,strong) NSMutableArray *arr_SelectedObjects;
@property (nonatomic,strong) NSMutableArray *arr_SubsectionData;
@property (nonatomic,strong) NSIndexPath *selectedIndexPath;

@property (nonatomic,assign) BOOL isTableEditing;
@property (nonatomic,assign) BOOL selectAll;
@property (nonatomic,assign) NSInteger alertCount;

@property (nonatomic,strong) OEXHelperVideoDownload *currentTappedVideo;
@property (nonatomic,strong) OEXVideoPlayerInterface *videoPlayerInterface;
@property (nonatomic,strong) NSURL *currentVideoURL;

@property (nonatomic,strong) UILabel *noDataLabel;

@end

@implementation TDVidoDownloadViewController

- (NSMutableArray *)arr_SubsectionData {
    if (!_arr_SubsectionData) {
        _arr_SubsectionData = [[NSMutableArray alloc] init];
    }
    return _arr_SubsectionData;
}

- (NSMutableArray *)arr_CourseData {
    if (!_arr_CourseData) {
        _arr_CourseData = [[NSMutableArray alloc] init];
    }
    return _arr_CourseData;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleViewLabel.text = NSLocalizedString(@"RECENT_VIDEOS", nil);
    self.isTableEditing = NO;
    self.selectAll = NO;
    
    [self setViewContraint];
    [self buttonAddTarge];
    
    [self addPlayerObserver];
    
    [self addActionObserverTarge];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
}

- (void)addActionObserverTarge {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAllChanged:) name:@"Navigation_SelectAll_Handle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subDownloadAppear:) name:@"TD_SubDowload_Appear" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadViewDisapear:) name:@"TD_Download_Disapear" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navigationStateChangedWithNotification:) name:OEXSideNavigationChangedStateKey object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidEnterFullScreen:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieWillExitFullScreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

- (void)playVideoForIndexPath:(NSIndexPath*)indexPath {
    
    NSArray* videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];
    
    self.currentTappedVideo = [videos objectAtIndex:indexPath.row];
    
    [self activatePlayer];
    
    // Set the path of the downloaded videos
    [self.dataInterface downloadAllTranscriptsForVideo:self.currentTappedVideo];
    
    NSFileManager* filemgr = [NSFileManager defaultManager];
    NSString* slink = [self.currentTappedVideo.filePath stringByAppendingPathExtension:@"mp4"];
    if(![filemgr fileExistsAtPath:slink]) {
        NSError* error = nil;
        [filemgr createSymbolicLinkAtPath:slink withDestinationPath:self.currentTappedVideo.filePath error:&error];
        
        if(error) {
            [self showAlert:OEXAlertTypePlayBackErrorAlert];
        }
    }
    
//    self.video_containerView.hidden = NO;
    [_videoPlayerInterface setShouldRotate:YES];
    [self.videoPlayerInterface.moviePlayerController stop];
    self.currentVideoURL = [NSURL fileURLWithPath:self.currentTappedVideo.filePath];
    [self handleComponentsFrame];
    
//    self.lbl_videoHeader.text = [NSString stringWithFormat:@"%@ ", self.currentTappedVideo.summary.name];
    
    [_videoPlayerInterface playVideoFor:self.currentTappedVideo];
    
    // Send Analytics
    [self.dataInterface sendAnalyticsEvents:OEXVideoStatePlay withCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime forVideo:self.currentTappedVideo];
}

- (void)handleComponentsFrame {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
//        self.videoViewHeight.constant = self.view.bounds.size.width * STANDARD_VIDEO_ASPECT_RATIO;//视频的高度
        self.videoPlayerInterface.height = self.view.bounds.size.width * STANDARD_VIDEO_ASPECT_RATIO;
        self.videoPlayerInterface.width = self.view.bounds.size.width;
        
        [self showVideoViewHeight:YES showEditeView:NO];
        
//        [self.recentEditViewHeight setConstant:0.0f];//编辑的高度
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)showVideoViewHeight:(BOOL)showVideo showEditeView:(BOOL)showEdite {
    
    CGFloat videoHeight = showVideo ? self.view.bounds.size.width * STANDARD_VIDEO_ASPECT_RATIO : 0.0;
    CGFloat editeHeight = showEdite ? 50.0 : 0.0;
    
    [self.video_containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.height.mas_equalTo(videoHeight);
    }];
    
    [self.customEditing mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(0);
        make.height.mas_equalTo(editeHeight);
    }];
}

- (void)activatePlayer {
    if(!_videoPlayerInterface) {
        //Initiate player object
        self.videoPlayerInterface = [[OEXVideoPlayerInterface alloc] init];
        [self.videoPlayerInterface enableFullscreenAutorotation];
        self.videoPlayerInterface.delegate = self;
        
        [self addChildViewController:self.videoPlayerInterface];
        [self.videoPlayerInterface didMoveToParentViewController:self];
        
        _videoPlayerInterface.videoPlayerVideoView = self.videoVideo;
        [self addPlayerObserver];
        if(_videoPlayerInterface) {
            [self.videoPlayerInterface videoPlayerShouldRotate];
        }
        self.videoPlayerInterface.moviePlayerController.controls.isShownOnMyVideos = YES;
    }
}

- (void)addPlayerObserver {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_VIDEO_PLAYER_NEXT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_VIDEO_PLAYER_PREVIOUS object:nil];
    
    //Add oserver
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackEnded:) name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}

- (void)removePlayerObserver {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_VIDEO_PLAYER_NEXT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_VIDEO_PLAYER_PREVIOUS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
}

- (void)playbackStateChanged:(NSNotification*)notification {
    switch([_videoPlayerInterface.moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            OEXLogInfo(@"VIDEO", @"Stopped");
            OEXLogInfo(@"VIDEO", @"Player current current duration %f total duration %f ", self.videoPlayerInterface.moviePlayerController.currentPlaybackTime, self.videoPlayerInterface.moviePlayerController.duration);
            break;
        case MPMoviePlaybackStatePlaying:
            
            if(_currentTappedVideo.watchedState == OEXPlayedStateWatched) {
                OEXLogInfo(@"VIDEO", @"Playing watched video");
            }
            else {
                //Buffering view
                OEXLogInfo(@"VIDEO", @"Playing unwatched video");
                if(_currentTappedVideo.watchedState != OEXPlayedStatePartiallyWatched) {
                    [self.dataInterface markVideoState:OEXPlayedStatePartiallyWatched forVideo:_currentTappedVideo];
                }
                _currentTappedVideo.watchedState = OEXPlayedStatePartiallyWatched;
            }
            
            break;
        case MPMoviePlaybackStatePaused:
            OEXLogInfo(@"VIDEO", @"Paused");
            break;
        case MPMoviePlaybackStateInterrupted:
            OEXLogInfo(@"VIDEO", @"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            OEXLogInfo(@"VIDEO", @"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            OEXLogInfo(@"VIDEO", @"Seeking Backward");
            break;
    }
    
    [self.tableView reloadData];
}

- (void)playbackEnded:(NSNotification*)notification {
    OEXLogInfo(@"VIDEO", @"Player current current duration %f total duration %f ", self.videoPlayerInterface.moviePlayerController.currentPlaybackTime, self.videoPlayerInterface.moviePlayerController.duration);
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        int currentTime = self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
        int totalTime = self.videoPlayerInterface.moviePlayerController.duration;
        
        if(currentTime == totalTime && totalTime > 0) {
            [self.dataInterface markLastPlayedInterval:0.0 forVideo:_currentTappedVideo];
            
            self.videoPlayerInterface.moviePlayerController.currentPlaybackTime = 0.0;
            
            _currentTappedVideo.watchedState = OEXPlayedStateWatched;
            [self.dataInterface markVideoState:OEXPlayedStateWatched forVideo:_currentTappedVideo];
            
            [self.tableView reloadData];
        }
    }
    else if(reason == MPMovieFinishReasonUserExited) {
    }
    else if(reason == MPMovieFinishReasonPlaybackError) {
        if([_currentTappedVideo.summary.videoURL isEqualToString:@""]) {
            [self showAlert:OEXAlertTypePlayBackContentUnAvailable];
        }
    }
}

- (void)resetPlayer {
    if(_videoPlayerInterface) {
        [self.videoPlayerInterface removeFromParentViewController];
        
        [self.videoPlayerInterface.moviePlayerController stop];
        [self removePlayerObserver];
        [_videoPlayerInterface resetPlayer];
        _videoPlayerInterface = nil;
    }
}

#pragma mark - videoPlayer Delegate

- (void)movieTimedOut {
    if(!_videoPlayerInterface.moviePlayerController.isFullscreen) {
        [self showOverlayMessage:[Strings timeoutCheckInternetConnection]];
        [_videoPlayerInterface.moviePlayerController stop];
    }
    else {
        [self showAlert:OEXAlertTypeVideoTimeOutAlert];
    }
}

- (void) videoPlayerTapped:(UIGestureRecognizer *)sender {
    // TODO: Handle player tap
}

#pragma mark - notification Action

- (void)movieDidEnterFullScreen:(NSNotification *)info {
    if (self.fullScreenHanle) {
        self.fullScreenHanle(YES);
    }
}

- (void)movieWillExitFullScreen:(NSNotification *)info {
    if (self.fullScreenHanle) {
        self.fullScreenHanle(NO);
    }
}

- (void)navigationStateChangedWithNotification:(NSNotification*)notification {
    OEXSideNavigationState state = [notification.userInfo[OEXSideNavigationChangedStateKey] unsignedIntegerValue];
    [self navigationChangedToState:state];
}

- (void)navigationChangedToState:(OEXSideNavigationState)state {
    switch(state) {
        case OEXSideNavigationStateVisible:
            [self addPlayerObserver];
            [_videoPlayerInterface setShouldRotate:YES];
            break;
        case OEXSideNavigationStateHidden:
            [_videoPlayerInterface.moviePlayerController setFullscreen:NO];
            [_videoPlayerInterface setShouldRotate:NO];
            [self removePlayerObserver];
            [_videoPlayerInterface.moviePlayerController pause];
            break;
    }
}

- (void)downloadViewDisapear:(NSNotification *)info {
    
    [self removePlayerObserver];
    [self removeOtherObserver];
}

- (void)removeOtherObserver {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Navigation_SelectAll_Handle" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TD_SubDowload_Appear" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OEXSideNavigationChangedStateKey object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

- (void)subDownloadAppear:(NSNotification *)info {
    
    self.currentTappedVideo = nil;
    
    [self resetPlayer];
    [_videoPlayerInterface resetPlayer];
    _videoPlayerInterface = nil;
    
    [self cancelTableClicked:nil];
    [self showVideoViewHeight:NO showEditeView:YES];
}

- (void)selectAllChanged:(NSNotification *)info { //点击选择全部
    
    if(self.selectAll) {
        // de-select all the videos to delete
        
        self.selectAll = NO;
        
        for(NSDictionary* dict in self.arr_CourseData) {
            for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
                obj_video.isSelected = NO;
                [self.arr_SelectedObjects removeObject:obj_video];
            }
        }
    }
    else {
        // remove all objects to avoids number problem
        [self.arr_SelectedObjects removeAllObjects];
        
        // select all the videos to delete
        
        self.selectAll = YES;
        
        for(NSDictionary* dict in self.arr_CourseData) {
            for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
                obj_video.isSelected = YES;
                [self.arr_SelectedObjects addObject:obj_video];
            }
        }
    }
    
    [self.tableView reloadData];
    
    [self disableDeleteButton];
}

- (void)buttonAddTarge {
    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)editTableClicked:(id)sender { //编辑
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];

    // SHIFT THE PROGRESS TO LEFT
//    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;

    [self hideComponentsOnEditing:YES];

    [self.tableView reloadData];
}

- (void)deleteTableClicked:(id)sender {//删除
    if(self.arr_SelectedObjects.count > 0) {
        [self showAlert:OEXAlertTypeDeleteConfirmationAlert];
    }
}

- (void)cancelTableClicked:(id)sender {//取消
    // set isSelected to NO for all the objects
    for(NSDictionary* dict in self.arr_CourseData) {
        for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
            obj_video.isSelected = NO;
        }
    }
    
    [self.arr_SelectedObjects removeAllObjects];

    [self disableDeleteButton];
//
//    // SHIFT THE PROGRESS TO LEFT
//    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;
//    
    [self hideComponentsOnEditing:NO];
    [self.tableView reloadData];
}

- (void)hideComponentsOnEditing:(BOOL)hide {
    
    self.isTableEditing = hide;
    
    self.customEditing.btn_Edit.hidden = hide;
    self.customEditing.btn_Cancel.hidden = !hide;
    self.customEditing.btn_Delete.hidden = !hide;
    self.customEditing.imgSeparator.hidden = !hide;
    
//    self.btn_SelectAllEditing.hidden = !hide;
//    self.btn_SelectAllEditing.checked = NO;
    
    [self handleEditeCheck:NO hidden:!hide];
    
    if (self.judgEditeHandle) {
        self.judgEditeHandle(hide);
    }
    
    self.selectAll = NO;
}

- (void)handleEditeCheck:(BOOL)checked hidden:(BOOL)hidden {
    
    if (self.checkEditeHandle) {
        self.checkEditeHandle(checked);
    }
    
    if (self.hideEditeHandle) {
        self.hideEditeHandle(hidden);
    }
}

#pragma mark - tableView Delegate 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    self.noDataLabel.hidden = self.arr_CourseData.count == 0 ? NO : YES;
    return [self.arr_CourseData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    _selectedIndexPath = nil;
    return [[[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TDDownloadSubCell *cell = [[TDDownloadSubCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TDDownloadSubCell"];
    
    NSArray *videos = [[self.arr_CourseData objectAtIndex:indexPath.section] objectForKey:CAV_KEY_RECENT_VIDEOS];
    OEXHelperVideoDownload *obj_video = [videos objectAtIndex:indexPath.row];
    cell.lbl_Title.text = obj_video.summary.name;
    if([cell.lbl_Title.text length] == 0) {
        cell.lbl_Title.text = @"(Untitled)";
    }
    
    double size = [obj_video.summary.size doubleValue];
    float result = ((size / 1024) / 1024);
    cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB", result];
    
    if(!obj_video.summary.duration) {
        cell.lbl_Time.text = @"NA";
    } else {
        cell.lbl_Time.text = [OEXDateFormatting formatSecondsAsVideoLength: [obj_video.summary.duration doubleValue]];
    }
    
    //Played state
    NSString *imageStr = @"ic_unwatched.png";
    if(obj_video.watchedState == OEXPlayedStateWatched) {
        imageStr = @"ic_watched.png";
    } else if(obj_video.watchedState == OEXPlayedStatePartiallyWatched) {
        imageStr = @"ic_partiallywatched.png";
    }
    cell.img_VideoWatchState.image = [UIImage imageNamed:imageStr];
    
    // WHILE EDITING
    if(self.isTableEditing) {
        // Unhide the checkbox and set the tag
        cell.btn_CheckboxDelete.hidden = NO;
        if ([self isRTL]) {
            cell.btn_CheckboxDelete.alpha = 0;
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
                cell.btn_CheckboxDelete.alpha = 1;
            }];
        }
        cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row;
        [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventValueChanged];
        cell.btn_CheckboxDelete.checked = obj_video.isSelected; // Toggle between selected and unselected checkbox
        
    } else {
        if ([self isRTL]) {
            [UIView animateWithDuration:0.2 animations:^{
                [self.view layoutIfNeeded];
                cell.btn_CheckboxDelete.alpha = 0;
            } completion:^(BOOL finished) {
                cell.btn_CheckboxDelete.hidden = YES;
            }];
            
        } else {
            cell.btn_CheckboxDelete.hidden = YES;
        }
        if(self.currentTappedVideo == obj_video && !self.isTableEditing) {
            [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
            _selectedIndexPath = indexPath;
        }
    }
    
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
    
    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    
    UIView* backview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    [backview setBackgroundColor:SELECTED_CELL_COLOR];
    cell.selectedBackgroundView = backview;
    if(indexPath == _selectedIndexPath) {
        [cell setSelected:YES animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // To avoid showing selected cell index of old video when new video is played
    self.dataInterface.selectedCCIndex = -1;
    self.dataInterface.selectedVideoSpeedIndex = -1;
    
    clickedIndexpath = indexPath;
    
    if(!self.isTableEditing) {
        // Check for disabling the prev/next videos
        [self CheckIfFirstVideoPlayed:indexPath];
        
        [self CheckIfLastVideoPlayed:indexPath];
        
        //Deselect previously selected row
        
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:_selectedIndexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        _selectedIndexPath = indexPath;
        
        [self playVideoForIndexPath:indexPath];
    }
    else {
        _selectedIndexPath = nil;
    }
    
    [self.tableView reloadData];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return RECENT_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSDictionary *dictVideo = [self.arr_CourseData objectAtIndex:section];
    OEXCourse *obj_course = [dictVideo objectForKey:CAV_KEY_COURSE];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, RECENT_HEADER_HEIGHT )];
    view.backgroundColor = GREY_COLOR;
    
    UILabel* courseTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, tableView.frame.size.width - 20, RECENT_HEADER_HEIGHT)];
    courseTitle.numberOfLines = 2;
    courseTitle.text = obj_course.name;
    courseTitle.font = [[OEXStyles sharedStyles] semiBoldSansSerifOfSize:14.0f];
    courseTitle.textColor = [UIColor colorWithRed:69.0 / 255.0 green:73.0 / 255.0 blue:81.0 / 255.0 alpha:1.0];
    [view addSubview:courseTitle];
    
    return view;
}

- (void)setSelectedCellAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView {
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
}

- (void)selectCheckbox:(id)sender {
    
    NSInteger section = ([sender tag]) / 100;
    NSInteger row = ([sender tag]) % 100;
    
    NSArray* videos = [[self.arr_CourseData objectAtIndex:section] objectForKey:CAV_KEY_RECENT_VIDEOS];
    OEXHelperVideoDownload* obj_video = [videos objectAtIndex:row];
    
    // change status of the object and reload table
    
    if(obj_video.isSelected) {
        obj_video.isSelected = NO;
        [self.arr_SelectedObjects removeObject:obj_video];
    }
    else {
        obj_video.isSelected = YES;
        
        [self.arr_SelectedObjects addObject:obj_video];
    }
    
    [self checkIfAllSelected];
    
    [self.tableView reloadData];
    
    [self disableDeleteButton];
}

- (void)checkIfAllSelected {
    
    // check if all the boxes checked on table then show SelectAll checkbox checked
    BOOL flagBreaked = NO;
    
    for(NSDictionary* dict in self.arr_CourseData) {
        for(OEXHelperVideoDownload* obj_video in [dict objectForKey : CAV_KEY_RECENT_VIDEOS]) {
            if(!obj_video.isSelected) {
                self.selectAll = NO;
                flagBreaked = YES;
                break;
                
            } else {
                self.selectAll = YES;
            }
        }
        
        if(flagBreaked) {
            break;
        }
    }
    
//    self.btn_SelectAllEditing.checked = self.selectAll;
    if (self.checkEditeHandle) {
        self.checkEditeHandle(self.selectAll);
    }
}

- (void)disableDeleteButton {
    
    if([self.arr_SelectedObjects count] == 0) {
        self.customEditing.btn_Delete.enabled = NO;
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
    } else {
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor clearColor]];
        self.customEditing.btn_Delete.enabled = YES;
    }
}

#pragma mark - play previous video from the list

- (void)CheckIfFirstVideoPlayed:(NSIndexPath*)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        // Post notification to hide the next button
        // We are playing the last video
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"YES"}];
    }
    else {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"NO"}];
    }
}

- (void)playPreviousVideo {
    NSIndexPath* indexPath = [self getPreviousVideoIndex];
    if(indexPath) {
        [self CheckIfFirstVideoPlayed:indexPath];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (NSIndexPath *)getPreviousVideoIndex {
    NSIndexPath* indexPath = nil;
    NSIndexPath* currentIndexPath = clickedIndexpath;
    NSInteger row = currentIndexPath.row;
    NSInteger section = currentIndexPath.section;
    
    // Check for the last video in the list
    if(currentIndexPath.section == 0) {
        if(currentIndexPath.row == 0) {
            //NSLog(@"Disable previous button");
            
            return nil;
        }
        else {
            indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:section];
        }
    }
    else {
        if(row > 0) {
            indexPath = [NSIndexPath indexPathForRow:row - 1 inSection:section];
        }
        else {
            NSInteger rowcount = [self.tableView numberOfRowsInSection:section - 1];
            indexPath = [NSIndexPath indexPathForRow:rowcount - 1 inSection:section - 1];
        }
    }
    
    return indexPath;
}

#pragma mark - Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath*)indexPath {
    NSInteger totalSections = [self.tableView numberOfSections];
    // get last index of the table
    NSInteger totalRows = [self.tableView numberOfRowsInSection:totalSections - 1];
    
    if(indexPath.section == totalSections - 1 && indexPath.row == totalRows - 1) {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else {
        // Not the last video is playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }
}

- (void)playNextVideo {
    NSIndexPath* indexPath = [self getNextVideoIndex];
    
    if(indexPath) {
        [self CheckIfLastVideoPlayed:indexPath];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)showAlertForNextLecture {
    NSIndexPath* indexPath = [self getNextVideoIndex];
    
    if(indexPath) {
        [self showAlert:OEXAlertTypeNextVideoAlert];
    }
}

// get next video index path

- (NSIndexPath *)getNextVideoIndex {
    
    NSIndexPath* indexPath = nil;
    NSIndexPath* currentIndexPath = clickedIndexpath;
    NSInteger row = currentIndexPath.row;
    NSInteger section = currentIndexPath.section;
    
    NSInteger totalSection = [self.tableView numberOfSections];
    if(currentIndexPath.section >= (totalSection - 1)) {
        NSInteger rowcount = [self.tableView numberOfRowsInSection:totalSection - 1];
        if(currentIndexPath.row >= rowcount - 1) {
            return nil;
        }
    }
    
    if([self.tableView numberOfSections] > 1) {
        NSInteger rowcount = [self.tableView numberOfRowsInSection:section];
        
        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
        else {
            NSInteger sectionCount = [self.tableView numberOfSections];
            
            if(section + 1 < sectionCount) {
                indexPath = [NSIndexPath indexPathForRow:0 inSection:section + 1];
            }
        }
    }
    else {
        NSInteger rowcount = [self.tableView numberOfRowsInSection:section];
        if(row + 1 < rowcount) {
            indexPath = [NSIndexPath indexPathForRow:row + 1 inSection:section];
        }
    }
    
    return indexPath;
}

#pragma mark - alert Delegate
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 1001) {
        if(buttonIndex == 1) {
            [self playNextVideo];
        }
    }
    else if(alertView.tag == 1002) {
        if(buttonIndex == 1) {
            NSInteger deleteCount = 0;
            
            for(OEXHelperVideoDownload* selectedVideo in self.arr_SelectedObjects) {
                // make a copy of array to avoid GeneralException(updation of array in loop) - crashes app
                
                NSMutableArray* arrCopySubsection = [self.arr_CourseData mutableCopy];
                
                NSInteger index = -1;
                
                for(NSDictionary* dict in arrCopySubsection) {
                    index++;
                    NSMutableArray* arrvideos = [[dict objectForKey:CAV_KEY_RECENT_VIDEOS] mutableCopy];
                    
                    for(OEXHelperVideoDownload* videos in arrvideos) {
                        if(selectedVideo == videos) {
                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] removeObject:videos];
                            
                            // remove for key CAV_KEY_VIDEOS also to maintain consistency.
                            // As it is unsorted array used to sort and put in array for key CAV_KEY_RECENT_VIDEOS
                            
                            [[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_VIDEOS] removeObject:videos];
                            
                            [[OEXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.summary.videoID completionHandler:^(BOOL success) {
                                selectedVideo.downloadState = OEXDownloadStateNew;
                                selectedVideo.downloadProgress = 0.0;
                                selectedVideo.isVideoDownloading = NO;
                            }];
                            
                            deleteCount++;
                            // if no objects in a particular section then remove the array
                            if([[[self.arr_CourseData objectAtIndex:index] objectForKey:CAV_KEY_RECENT_VIDEOS] count] == 0) {
                                [self.arr_CourseData removeObject:dict];
                            }
                        }
                    }
                }
            }
            
            // if no objects to show
            if([self.arr_CourseData count] == 0) {
//                self.btn_SelectAllEditing.hidden = YES;
//                self.btn_SelectAllEditing.checked = NO;
                [self handleEditeCheck:NO hidden:YES];
                
                self.isTableEditing = NO;
                [self showVideoViewHeight:NO showEditeView:NO];
//                [self.recentEditViewHeight setConstant:0.0];
                self.tableView.hidden = YES;
            }
            
            [self.tableView reloadData];
            
            if (self.reloadSubDataHandle) {
                self.reloadSubDataHandle();
            }
            
            // clear all objects form array after deletion.
            // To obtain correct count on next deletion process.
            [self.arr_SelectedObjects removeAllObjects];
        }
        
        [self cancelTableClicked:nil];
    }
    else if(alertView.tag == 1005 || alertView.tag == 1006) {
    }
    
    if(self.alertCount > 0) {
        self.alertCount = _alertCount - 1;
    }
    if(self.alertCount == 0) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:YES];
        [_videoPlayerInterface orientationChanged:nil];
    }
}


- (void)showAlert:(OEXAlertType )OEXAlertType {
    self.alertCount = _alertCount + 1;
    
    if(self.alertCount >= 1) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:NO];
    }
    
    switch(OEXAlertType) {
        case OEXAlertTypeDeleteConfirmationAlert: {
            NSString* message = [Strings confirmDeleteMessage:_arr_SelectedObjects.count];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings confirmDeleteTitle]
                                                            message:[NSString stringWithFormat:message, _arr_SelectedObjects.count]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings cancel]
                                                  otherButtonTitles:[Strings delete], nil];
            alert.tag = 1002;
            [alert show];
        }
            
            break;
            
        case OEXAlertTypeNextVideoAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings playbackCompleteTitle]
                                                            message:[Strings playbackCompleteMessage]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings playbackCompleteContinueCancel]
                                                  otherButtonTitles:[Strings playbackCompleteContinue], nil];
            alert.tag = 1001;
            alert.delegate = self;
            [alert show];
        }
            break;
            
        case OEXAlertTypePlayBackErrorAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings videoContentNotAvailable]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:[Strings close]
                                                  otherButtonTitles:nil, nil];
            
            alert.tag = 1003;
            [alert show];
        }
            
            break;
            
        case OEXAlertTypeVideoTimeOutAlert: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings timeoutAlertTitle]
                                                            message:[Strings timeoutCheckInternetConnection]
                                                           delegate:self
                                                  cancelButtonTitle:[Strings ok]
                                                  otherButtonTitles:nil];
            alert.tag = 1004;
            [alert show];
        }
            break;
            
        case OEXAlertTypePlayBackContentUnAvailable: {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings videoContentNotAvailable]
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:[Strings close]
                                                  otherButtonTitles:nil];
            alert.tag = 1005;
            [alert show];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Orientation methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL) isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.videoPlayerInterface.moviePlayerController.fullscreen;
}

#pragma mark - UI
- (void)setViewContraint {
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.separatorColor = [UIColor colorWithHexString:colorHexStr7];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    self.tableView.exclusiveTouch = YES;
    [self.view addSubview:self.tableView];
    
    self.video_containerView = [[UIView alloc] init];
    [self.view addSubview:self.video_containerView];
    
    self.videoVideo = [[UIView alloc] init];
    self.videoVideo.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    [self.video_containerView addSubview:self.videoVideo];
    
    self.customEditing = [[TDEditeBottomView alloc] init];
    [self.view addSubview:self.customEditing];
    
    self.noDataLabel = [[UILabel alloc] init];
    self.noDataLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    self.noDataLabel.textColor = [UIColor colorWithHexString:colorHexStr8];
    self.noDataLabel.text = [Strings noVideosDownloaded];
    self.noDataLabel.hidden = YES;
    self.noDataLabel.numberOfLines = 0;
    self.noDataLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView addSubview:self.noDataLabel];
    
    [self.video_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.view);
        make.height.mas_equalTo(0);
    }];
    
    [self.videoVideo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self.video_containerView);
    }];
    
    [self.customEditing mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.bottom.mas_equalTo(self.view.mas_bottom).offset(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.video_containerView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(self.customEditing.mas_top);
    }];
    
    [self.noDataLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.tableView);
        make.width.mas_equalTo(TDWidth - 18);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
