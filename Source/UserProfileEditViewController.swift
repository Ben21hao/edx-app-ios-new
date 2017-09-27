//
//  UserProfileEditViewController.swift
//  edX
//
//  Created by Michael Katz on 9/28/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

let MiB = 1_048_576

extension UserProfile : FormData {
    
    func valueForField(key: String) -> String? {
        guard let field = ProfileFields(rawValue: key) else { return nil }
        
        switch field {
        case .YearOfBirth:
            return birthYear.flatMap{ String($0) }
        case .LanguagePreferences:
            return languageCode
        case .Country:
            return countryCode
        case .Bio:
            return bio
        case .AccountPrivacy:
            return accountPrivacy?.rawValue
        case .Education:
            return educationCode.flatMap{ String($0) }
        case .Nickname:
            return nickname
        case .email:
            return email
        case .phone:
            return phone
        default:
            return nil
        }
    }
    
    func displayValueForKey(key: String) -> String? {
        guard let field = ProfileFields(rawValue: key) else { return nil }
        
        switch field {
        case .YearOfBirth:
            return birthYear.flatMap{ String($0) }
        case .LanguagePreferences:
            return language
        case .Country:
            return country
        case .Bio:
            return bio
        case .Education:
            return educat
        case .Nickname:
            return nickname
        case .email:
            return email
        case .phone:
            return phone
        default:
            return nil
        }
    }
    
    func setValue(value: String?, key: String) {
        guard let field = ProfileFields(rawValue: key) else { return }
        switch field {
        case .YearOfBirth:
            let newValue = value.flatMap { Int($0) }
            if newValue != birthYear {
                updateDictionary[key] = newValue ?? NSNull()
            }
            birthYear = newValue
        case .LanguagePreferences:
            let changed =  value != languageCode
            languageCode = value
            if changed {
                updateDictionary[key] = preferredLanguages ?? NSNull()
            }
        case .Country:
            if value != countryCode {
                updateDictionary[key] = value ?? NSNull()
            }
            countryCode = value
        case .Bio:
            if value != bio {
                updateDictionary[key] = value ?? NSNull()
            }
            bio = value
        case .Education:
            if value != educationCode {
                updateDictionary[key] = value ?? NSNull()
            }
            educationCode = value
        case .Nickname:
            if value != nickname {
                updateDictionary[key] = value ?? NSNull()
            }
            nickname = value
        case .email:
            if value != email {
                updateDictionary[key] = value ?? NSNull()
            }
            email = value
        case .phone:
            if value != phone {
                updateDictionary[key] = value ?? NSNull()
            }
            phone = value
            
        case .AccountPrivacy:
            setLimitedProfile(NSString(string: value!).boolValue)
        default: break
            
        }
    }
}

class UserProfileEditViewController: UITableViewController,UIGestureRecognizerDelegate,UIAlertViewDelegate {
    
    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider>
    
    var profile: UserProfile
    let environment: Environment
    var disabledFields = [String]()
    var imagePicker: ProfilePictureTaker?
    var banner: ProfileBanner!
    let footer = UIView()
    var titleLabel : UILabel?
    
    init(profile: UserProfile, environment: Environment) {
        self.profile = profile
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var fields: [JSONFormBuilder.Field] = []
    
    private let toast = ErrorToastView()
    private let headerHeight: CGFloat = 72
    private let spinner = SpinnerView(size: SpinnerView.Size.Large, color: SpinnerView.Color.Primary)
    
    private func makeHeader() -> UIView {
        banner = ProfileBanner(editable: true) { [weak self] in
            self?.imagePicker = ProfilePictureTaker(delegate: self!)
            self?.imagePicker?.start(self!.profile.hasProfileImage)
        }
        banner.style = .DarkContent
        banner.shortProfView.borderColor = OEXStyles.sharedStyles().neutralLight()
        banner.backgroundColor = tableView.backgroundColor
        
        let networkManager = environment.networkManager
        banner.showProfile(profile, networkManager: networkManager)
        
        
        let bannerWrapper = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: headerHeight))
        bannerWrapper.addSubview(banner)
        bannerWrapper.addSubview(toast)
        
        toast.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bannerWrapper)
            make.trailing.equalTo(bannerWrapper)
            make.leading.equalTo(bannerWrapper)
            make.height.equalTo(0)
        }
        
        banner.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(bannerWrapper)
            make.leading.equalTo(bannerWrapper)
            make.bottom.equalTo(bannerWrapper)
            make.top.equalTo(toast.snp_bottom)
        }
        
        let bottomLine = UIView()
        bottomLine.backgroundColor = OEXStyles.sharedStyles().baseColor6()
        bannerWrapper.addSubview(bottomLine)
        bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(bannerWrapper)
            make.right.equalTo(bannerWrapper)
            make.height.equalTo(1)
            make.bottom.equalTo(bannerWrapper)
        }
        
        return bannerWrapper
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNaviewgatinBar()
        
        tableView.tableHeaderView = makeHeader()
        tableView.tableFooterView = footer //get rid of extra lines when the content is shorter than a screen
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 48
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        if let form = JSONFormBuilder(jsonFile: "profiles") {
            JSONFormBuilder.registerCells(tableView)
            fields = form.fields!
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserProfileEditViewController.reloadProfile(_:)), name: "NiNameNotification_Change", object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
//        let viewHeight = view.bounds.height
//        var footerFrame = footer.frame
//        let footerViewRect = footer.superview!.convertRect(footerFrame, toView: view)
//        footerFrame.size.height = viewHeight - CGRectGetMinY(footerViewRect)
//        footer.frame = footerFrame
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenProfileEdit)

        hideToast()
        updateProfile()
        reloadViews()
    }
    
    func setNaviewgatinBar() {
        
        let leftButton = UIButton.init(frame: CGRectMake(0, 0, 48, 48))
        leftButton.setImage(UIImage.init(named: "backImagee"), forState: .Normal)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -23, 0, 23)
        leftButton.addTarget(self, action: #selector(leftBarItemAction), forControlEvents: .TouchUpInside)
        
        self.navigationController?.interactivePopGestureRecognizer?.enabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let leftBarItem = UIBarButtonItem.init(customView: leftButton)
        self.navigationItem.leftBarButtonItem = leftBarItem
        
        //添加标题文本
        self.titleLabel = UILabel(frame:CGRect(x:0, y:0, width:40, height:40))
        self.titleLabel?.text = Strings.Profile.editTitle
        self.titleLabel?.font = UIFont(name:"OpenSans",size:18.0)
        self.titleLabel?.textColor = UIColor.whiteColor()
        self.navigationItem.titleView = self.titleLabel
        
        navigationItem.backBarButtonItem?.title = " "
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont(name: "OpenSans", size: 18.0)!]
    }
    
    func leftBarItemAction() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func updateProfile() {
        
        if profile.hasUpdates {
            let fieldName = profile.updateDictionary.first!.0
            let field = fields.filter{$0.name == fieldName}[0]
            let fieldDescription = field.title!
            
            view.addSubview(spinner)
            spinner.snp_makeConstraints { (make) -> Void in
                make.center.equalTo(view)
            }
            
            environment.dataManager.userProfileManager.updateCurrentUserProfile(profile) {[weak self] result in
                self?.spinner.removeFromSuperview()
                if let newProf = result.value {
                    self?.profile = newProf
                    self?.reloadViews()
                } else {
                    let message = Strings.Profile.unableToSend(fieldName: fieldDescription)
                    self?.showToast(message)
                }
            }
        }
    }
    
    func reloadViews() {
        disableLimitedProfileCells(profile.sharingLimitedProfile)
        self.tableView.reloadData()
    }
    
    //MARK: tableView Delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fields.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= 5 {
            return 1
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let field = fields[indexPath.section]
        let cell = tableView.dequeueReusableCellWithIdentifier(field.cellIdentifier, forIndexPath: indexPath)
//        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.applyStandardSeparatorInsets()
        
        guard let formCell = cell as? FormCell else { return cell }
        formCell.applyData(field, data: profile)
        
        guard let segmentCell = formCell as? JSONFormBuilder.SegmentCell else { return cell }
        //if it's a segmentCell add the callback directly to the control. When we add other types of controls, this should be made more re-usable
        
        //remove actions before adding so there's not a ton of actions
        segmentCell.typeControl.oex_removeAllActions()
        segmentCell.typeControl.oex_addAction({ [weak self] sender in
            
            let control = sender as! UISegmentedControl
            let limitedProfile = control.selectedSegmentIndex == 1
            let newValue = String(limitedProfile)
            
            self?.profile.setValue(newValue, key: field.name)
            self?.updateProfile()
            self?.disableLimitedProfileCells(limitedProfile)
            self?.tableView.reloadData()
            }, forEvents: .ValueChanged)
        
        if let under13 = profile.parentalConsent where under13 == true {
            let descriptionStyle = OEXMutableTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
            segmentCell.descriptionLabel.attributedText = descriptionStyle.attributedStringWithText(Strings.Profile.ageLimit)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 88
        }
        return 58
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
       
        if indexPath.section <= 6 {
            let field = fields[indexPath.section]
            field.takeAction(profile, controller: self)
            
        } else {
            if indexPath.section == 7 {
                vertifitePassword(1)
                
            } else {
                vertifitePassword(2)
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = UIColor.whiteColor()
        
//        let field = fields[indexPath.section]
//        let enabled = !disabledFields.contains(field.name)
//        cell.userInteractionEnabled = enabled
//        cell.backgroundColor = enabled ? UIColor.clearColor() : OEXStyles.sharedStyles().neutralXLight()
    }
    
    func vertifitePassword(type : NSInteger) {
        
        tableView.scrollEnabled = false
        
        let alertView = TDAlertView.init()
        alertView.frame = CGRectMake(0, 0, TDScreenWidth,TDScreenHeight - 60)
        
        alertView.sureHandle = { (AnyObject) -> () in
            
            if AnyObject.characters.count == 0 {
                alertView.errorLabel.text = Strings.loginPassword
                alertView.vertifiFailed = true
                
            } else {
                let baseTool = TDBaseToolModel.init()
                baseTool.vertifiteLoginPassword(AnyObject, andName: self.profile.username, onView: self.view)
                
                baseTool.vertifitePasswordHandle = { (code: Int) in
                    
                    if code == 200 {
                        
                        alertView.removeFromSuperview()
                        self.jumpToController(type)
                        
                    } else {
                        alertView.errorLabel.text = Strings.passwordError
                        alertView.vertifiFailed = true
                    }
                }
            }
        }
        alertView.cancelHandle = { () -> () in
            alertView.removeFromSuperview()
        }
        self.view.addSubview(alertView)
    }
    
    func jumpToController(type : NSInteger) {
        
        if type == 1 {
            let emailVC = TDBindEmailViewController.init()
            emailVC.username = self.profile.username
            emailVC.bindEmailHandle = {(AnyObject) -> () in
                print("绑定邮箱 --- \(AnyObject)")
            }
            self.navigationController?.pushViewController(emailVC, animated: true)
            
        } else {
            let phoneVc = TDBindPhoneViewController.init()
            phoneVc.username = self.profile.username
            phoneVc.bindPhoneHandle = {(AnyObject) -> () in
                self.profile.phone = String(AnyObject)
                
                //                let networkRequest = ProfileAPI.profileUpdateRequest(self.profile)
                //                self.environment.networkManager.taskForRequest(networkRequest) { result in
                //                    if let _ = result.error {
                //                        self.showToast("绑定手机失败")
                //
                //                    } else {
                //                        self.showToast("成功绑定")
                //                    }
                //
                //                }
                print("绑定手机号 --- \(AnyObject) \(self.profile.phone)")
            }
            self.navigationController?.pushViewController(phoneVc, animated: true)
        }
    }

    private func disableLimitedProfileCells(disabled: Bool) {
        banner.changeButton.enabled = true
        if disabled {
            disabledFields = [UserProfile.ProfileFields.Country.rawValue,
                UserProfile.ProfileFields.LanguagePreferences.rawValue,
                UserProfile.ProfileFields.Bio.rawValue]
            if profile.parentalConsent ?? false {
                //If the user needs parental consent, they can only share a limited profile, so disable this field as well */
                disabledFields.append(UserProfile.ProfileFields.AccountPrivacy.rawValue)
                banner.changeButton.enabled = false 
            }
//            footer.backgroundColor = OEXStyles.sharedStyles().neutralWhite()
        } else {
//            footer.backgroundColor = UIColor.clearColor()
            disabledFields.removeAll()
        }
    }
  
    //MARK: - Update the toast view
    
    private func showToast(message: String) {
        toast.setMessage(message)
        setToastHeight(50)
    }
    
    private func hideToast() {
        setToastHeight(0)
    }
    
    private func setToastHeight(toastHeight: CGFloat) {
        toast.hidden = toastHeight <= 1
        toast.snp_updateConstraints(closure: { (make) -> Void in
            make.height.equalTo(toastHeight)
        })
        var headerFrame = self.tableView.tableHeaderView!.frame
        headerFrame.size.height = headerHeight + toastHeight
        self.tableView.tableHeaderView!.frame = headerFrame
        
        self.tableView.tableHeaderView = self.tableView.tableHeaderView
    }
    
    func showAlertView(type: NSInteger) {
        
        let infoDic : NSDictionary = NSBundle.mainBundle().infoDictionary!
        CFShow(infoDic)
        let appName : String = "\(infoDic["CFBundleDisplayName"]!)"
        
        let typeStr : String = type == 0 ? Strings.allowUseAlbumText(name: appName) : Strings.allowUseCameraText(name: appName)
        
        let alertView = UIAlertView.init(title: Strings.systemWaring, message: typeStr, delegate: self, cancelButtonTitle: Strings.cancel, otherButtonTitles: Strings.ok)
        alertView.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            gotoPhoneSystemSetting()
        }
    }
    
    func gotoPhoneSystemSetting() {
        UIApplication.sharedApplication().openURL(NSURL.init(string: UIApplicationOpenSettingsURLString)!)
    }
}


/** Error Toast */
private class ErrorToastView : UIView {
    let errorLabel = UILabel()
    let messageLabel = UILabel()
    
    init() {
        super.init(frame: CGRectZero)
        
        backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        addSubview(errorLabel)
        addSubview(messageLabel)
        
        errorLabel.backgroundColor = OEXStyles.sharedStyles().errorBase()
        let errorStyle = OEXMutableTextStyle(weight: .Light, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        errorStyle.alignment = .Center
        errorLabel.attributedText = Icon.Warning.attributedTextWithStyle(errorStyle)
        errorLabel.textAlignment = .Center
        
        messageLabel.adjustsFontSizeToFitWidth = true
        
        errorLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(errorLabel.snp_height)
        }
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(errorLabel.snp_trailing).offset(10)
            make.trailing.equalTo(self).offset(-10)
            make.centerY.equalTo(self.snp_centerY)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMessage(message: String) {
        let messageStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
        messageLabel.attributedText = messageStyle.attributedStringWithText(message)
    }

}

//MARK: imagePicker Delegate
extension UserProfileEditViewController : ProfilePictureTakerDelegate {
    
    func gotoSystemSettins(type: NSInteger) {
        self.showAlertView(type)
    }
    
    func showChooserAlert(alert: UIAlertController) {
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showImagePickerController(picker: UIImagePickerController) {
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    func deleteImage() {
        let endBlurimate = banner.shortProfView.blurimate()
        
        let networkRequest = ProfileAPI.deleteProfilePhotoRequest(profile.username!)
        environment.networkManager.taskForRequest(networkRequest) { result in
            if let _ = result.error {
                endBlurimate.remove()
                self.showToast(Strings.Profile.unableToRemovePhoto)
            } else {
                //Was sucessful upload
                self.reloadProfileFromImageChange(endBlurimate)
            }
        }
    }
    
    func imagePicked(image: UIImage, picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let resizedImage = image.resizedTo(CGSize(width: 500, height: 500))
        
        var quality: CGFloat = 1.0
        var data = UIImageJPEGRepresentation(resizedImage, quality)!
        while data.length > MiB && quality > 0 {
            quality -= 0.1
            data = UIImageJPEGRepresentation(resizedImage, quality)!
        }
        
        banner.shortProfView.image = image
        let endBlurimate = banner.shortProfView.blurimate()

        let networkRequest = ProfileAPI.uploadProfilePhotoRequest(profile.username!, imageData: data)
        environment.networkManager.taskForRequest(networkRequest) { result in
            let anaylticsSource = picker.sourceType == .Camera ? AnaylticsPhotoSource.Camera : AnaylticsPhotoSource.PhotoLibrary
            OEXAnalytics.sharedAnalytics().trackSetProfilePhoto(anaylticsSource)
            if let _ = result.error {
                endBlurimate.remove()
                self.showToast(Strings.Profile.unableToSetPhoto)
            } else {
                //Was successful delete
                self.reloadProfileFromImageChange(endBlurimate)
            }
        }
    }
    
    func cancelPicker(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    private func reloadProfileFromImageChange(completionRemovable: Removable) {
        let feed = self.environment.dataManager.userProfileManager.feedForCurrentUser()
        feed.refresh()
        feed.output.listenOnce(self, fireIfAlreadyLoaded: false) { result in
            completionRemovable.remove()
            if let newProf = result.value {
                self.profile = newProf
                self.reloadViews()
                self.banner.showProfile(newProf, networkManager: self.environment.networkManager)
            } else {
                self.showToast(Strings.Profile.unableToGet)
            }
        }
    }
    
    func reloadProfile(notifi : NSNotification) {
        
        let networkRequest = ProfileAPI.profileUpdateRequest(self.profile)
        environment.networkManager.taskForRequest(networkRequest) { result in
            if let _ = result.error {
                self.showToast("无法更新昵称")
                
            } else {
                let nickName = notifi.object?.valueForKey("nickName") as? String
                self.banner.usernameLabel.text = nickName
            }
        }
    }

}
