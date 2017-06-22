//
//  JSONFormBuilderTextEditor.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class JSONFormBuilderTextEditorViewController: TDSwiftBaseViewController {
    let textView = OEXPlaceholderTextView()
    let handInBtn = UIButton.init(type: .Custom)
    var text: String { return textView.text }
    
    var doneEditing: ((value: String)->())?
    
    init(text: String?, placeholder: String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.view = UIView()
        self.view.backgroundColor = UIColor.whiteColor()
        
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        textView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        //        textView.placeholder = "请输入昵称"
        textView.placeholderTextColor = OEXStyles.sharedStyles().neutralBase()
        textView.textColor = OEXStyles.sharedStyles().neutralBlackT()
        textView.font = UIFont.init(name: "OpenSans", size: 16)
        textView.backgroundColor = UIColor.whiteColor()
        textView.layer.cornerRadius = 4.0
        textView.layer.borderColor = UIColor.init(RGBHex: 0xccd1d9, alpha: 1).CGColor
        textView.layer.borderWidth = 0.5;
        textView.delegate = self
        
        textView.text = text ?? ""
        if let placeholder = placeholder {
            textView.placeholder = placeholder
        }
        
        handInBtn.setTitle(Strings.submit, forState: .Normal)
        handInBtn.addTarget(self, action: #selector(JSONFormBuilderTextEditorViewController.handinButtonAction), forControlEvents: .TouchUpInside)
        handInBtn.backgroundColor = OEXStyles.sharedStyles().baseColor1()
        handInBtn.layer.cornerRadius = 4.0
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        OEXAnalytics.sharedAnalytics().trackScreenWithName(OEXAnalyticsScreenEditTextFormValue)
    }

    private func setupViews() {
        view.addSubview(textView)
        
        textView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view.snp_topMargin).offset(18)
            make.leading.equalTo(view.snp_leadingMargin)
            make.trailing.equalTo(view.snp_trailingMargin)
            make.height.equalTo(41)
        }
        
        view.addSubview(handInBtn)
        handInBtn.snp_makeConstraints { (make) in
            make.top.equalTo(view.snp_topMargin).offset(77)
            make.leading.equalTo(view.snp_leadingMargin)
            make.trailing.equalTo(view.snp_trailingMargin)
            make.height.equalTo(41)
        }
    }
    
    func handinButtonAction() {
        self.textView.resignFirstResponder()
        
        if textView.text.characters.count == 0 { //昵称不能为空
            self.view.makeToast(Strings.nicknameNull, duration: 1.08, position: CSToastPositionCenter)
            
        } else if textView.text.characters.count == 1 {
            self.view.makeToast( Strings.aleastTeoCharacter, duration: 1.08, position: CSToastPositionCenter)
            
        } else if textView.text.characters.count <= 6 {
            let baseTool = TDBaseToolModel.init()
            baseTool.checkNickname(textView.text, view: self.view)
            baseTool.checkNickNameHandle = {(AnyObject) -> () in
                
                if AnyObject == true {
                    self.doneEditing?(value: self.textView.text) //block 反向传值
                    
                    let dic : NSDictionary = ["nickName" : self.textView.text]
                    NSNotificationCenter.defaultCenter().postNotificationName("NiNameNotification_Change", object:dic)
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
            
        } else { //不能超过六个字
            self.view.makeToast(Strings.nicknameNumber, duration: 1.08, position: CSToastPositionCenter)
        }
    }
    
//    override func willMoveToParentViewController(parent: UIViewController?) {
//        if parent == nil { //removing from the hierarchy
//            doneEditing?(value: textView.text)
//        }
//    }
}

extension JSONFormBuilderTextEditorViewController : UITextViewDelegate {
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
}
