//
//  Profile.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore

public class UserProfile {

    public enum ProfilePrivacy: String {
        case Private = "private"
        case Public = "all_users"
    }
    
    enum ProfileFields: String, RawStringExtractable {
        case Image = "profile_image"
        case HasImage = "has_image"
        case ImageURL = "image_url_full"
        case Username = "username"
        case user_id = "user_id" //用户id
        case LanguagePreferences = "language_proficiencies"
        case Country = "country"
        case Bio = "bio"
        case YearOfBirth = "year_of_birth"
        case ParentalConsent = "requires_parental_consent"
        case AccountPrivacy = "account_privacy"
        
        case Name = "name" //用户名
        case Education = "level_of_education"//学历
        case Nickname = "nickname"//昵称
        case Remainscore = "remainscore" //宝典
        case phone = "mobile"//手机号码
        case email = "email"//邮箱
        case coupon = "can_use_coupon_num"//优惠券
        case order = "wait_order_num"//未支付订单
        case vertify = "verify_status" //认证信息
        case code = "code"
        case companyDic = "company"//公司dic
        case logoUrl = "logo"//公司logo
        
    }
    
    let hasProfileImage: Bool
    let imageURL: String?
    let username: String?
    let user_id: Int? //用户id
    var preferredLanguages: [NSDictionary]?
    var countryCode: String?
    var bio: String?
    var birthYear: Int?
    
    let parentalConsent: Bool?
    var accountPrivacy: ProfilePrivacy?
    
    var hasUpdates: Bool { return updateDictionary.count > 0 }
    var updateDictionary = [String: AnyObject]()
    
    let statusCode : Int? //状态码 400 未认证，200 提交成功 ，201 已认证，202 认证失败
    let name : String?
    var educationCode : String?
    var nickname: String?//昵称
    var remainscore: Double?//宝典
    var phone : String?//手机号
    var email : String?//邮箱
    var coupon :  Double? //优惠券
    var order : Double?//未支付订单
    let logoUrl: String?//公司logo
    
    public init?(json: JSON) {
        let profileImage = json[ProfileFields.Image]
        if let hasImage = profileImage[ProfileFields.HasImage].bool where hasImage {
            hasProfileImage = true
            imageURL = profileImage[ProfileFields.ImageURL].string
        } else {
            hasProfileImage = false
            imageURL = nil
        }
        user_id = json[ProfileFields.user_id].int
        username = json[ProfileFields.Username].string
        preferredLanguages = json[ProfileFields.LanguagePreferences].arrayObject as? [NSDictionary]
        countryCode = json[ProfileFields.Country].string
        bio = json[ProfileFields.Bio].string
        birthYear = json[ProfileFields.YearOfBirth].int
        parentalConsent = json[ProfileFields.ParentalConsent].bool
        accountPrivacy = ProfilePrivacy(rawValue: json[ProfileFields.AccountPrivacy].string ?? "")
        
        let companyDic = json[ProfileFields.companyDic]
        logoUrl = companyDic[ProfileFields.logoUrl].string
        
        let profileStatus = json[ProfileFields.vertify]
        statusCode = profileStatus[ProfileFields.code].int
        
        phone = json[ProfileFields.phone].string //手机号
        email = json[ProfileFields.email].string//邮箱
        name = json[ProfileFields.Name].string//用户名
        nickname = json[ProfileFields.Nickname].string//昵称
        coupon = json[ProfileFields.coupon].double//优惠券
        order = json[ProfileFields.order].double//未支付订单
        remainscore = json[ProfileFields.Remainscore].double
        educationCode = json[ProfileFields.Education].string
        
        print("json-----\(json)")
    }
    
    internal init(user_id : Int, username : String, bio : String? = nil, parentalConsent : Bool? = false, countryCode : String? = nil, accountPrivacy : ProfilePrivacy? = nil,name : String, education : String? = nil,nickname : String,remainscore : Double,phone : String,email : String,coupon : Double,order : Double) {
        
        self.accountPrivacy = accountPrivacy
        self.username = username
        self.user_id = user_id
        self.hasProfileImage = false
        self.imageURL = nil
        self.parentalConsent = parentalConsent
        self.bio = bio
        self.countryCode = countryCode
        
        self.name = name
        self.statusCode = nil
        self.educationCode = education
        self.nickname = nickname
        self.remainscore = remainscore
        self.phone = phone
        self.email = email
        self.coupon = coupon
        self.order = order
        self.logoUrl = nil
    }
    
    var languageCode: String? {
        get {
            guard let languages = preferredLanguages where languages.count > 0 else { return nil }
            return languages[0]["code"] as? String
        }
        set {
            guard let code = newValue else { preferredLanguages = []; return }
            guard preferredLanguages != nil && preferredLanguages!.count > 0 else {
                preferredLanguages = [["code": code]]
                return
            }
            preferredLanguages!.replaceRange(0...0, with: [["code": code]])
        }
    }
}

extension UserProfile { //ViewModel
    func image(networkManager: NetworkManager) -> RemoteImage {
        let placeholder = UIImage(named: "default_big")
        if let url = imageURL where hasProfileImage {
            return RemoteImageImpl(url: url, networkManager: networkManager, placeholder: placeholder, persist: true)
        }
        else {
            return RemoteImageJustImage(image: placeholder)
        }
    }
    
    var country: String? {
        guard let code = countryCode else { return nil }
        return NSLocale.currentLocale().displayNameForKey(NSLocaleCountryCode, value: code)
    }
    
    var language: String? {
        return languageCode.flatMap { return NSLocale.currentLocale().displayNameForKey(NSLocaleLanguageCode, value: $0) }
    }
    
    var educat: String? {
        if educationCode == "p" {
            return Strings.dDegree
        } else if educationCode == "m" {
            return Strings.mDegree
        } else if educationCode == "b" {
            return Strings.bDegree
        } else if educationCode == "a" {
            return Strings.aDegree
        } else if educationCode == "hs" {
            return Strings.hsDegree
        } else if educationCode == "jhs" {
            return Strings.jhsDegree
        } else if educationCode == "el" {
            return Strings.elDegree
        } else if educationCode == "none" {
            return Strings.noneDegree
        } else if educationCode == "other" {
            return Strings.otherDegree
        } else {
            return educationCode
        }
    }
    
    var sharingLimitedProfile: Bool {
        get {
            return (parentalConsent ?? false) || (accountPrivacy == nil) || (accountPrivacy! == .Private)
        }
    }
    func setLimitedProfile(newValue:Bool) {
        let newStatus: ProfilePrivacy = newValue ? .Private: .Public
        if newStatus != accountPrivacy {
            updateDictionary[ProfileFields.AccountPrivacy.rawValue] = newStatus.rawValue
        }
        accountPrivacy = newStatus
    }
}
