//
//  CourseCatalogDetailView.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

private let margin : CGFloat = 5
private let width : CGFloat = UIScreen.mainScreen().bounds.size.width
import edXCore

class CourseCatalogDetailView : UIView, UIWebViewDelegate,UIScrollViewDelegate {
    //class CourseCatalogDetailView : UIView{
    
    private struct Field {
        let name : String
        let value : String
        let icon : Icon
    }
    
    typealias Environment = protocol<OEXAnalyticsProvider, DataManagerProvider, NetworkManagerProvider, OEXRouterProvider>
    
    private let environment : Environment
    //头部课程卡片
    internal let courseCard = CourseCardView()
    //课程介绍文本1
    internal let blurbLabel = UILabel()
    //    internal var blurbH : CGFloat
    //马上加入 | 查看课程 按钮
    internal let actionButton = SpinnerButton(type: .System)
    internal let giveLabel = UILabel() //赠送宝典信息
    //英文以上部分view
    internal let topContainer = UIView()
    //全文
    internal let moreBtn = UIButton()
    //更多课程详情
    internal let moreLabel = UILabel()
    internal var textView = TZStackView()
    //整个view
    internal let descriptionView = UIWebView()
    internal let myScrollV = UIScrollView()
    internal let playButton = UIButton()
    internal let timeV = UIView()//时长、报名人数
    
    internal let secondCell = UIView()//第二个cell
    internal let thirdCell = UIView()//第三个cell
    internal let fourthCell = UIView()//第四个cell
    internal let fivethCell = UIView()//课程cell
    internal let sixthCell = UIView()//课程cell
    
    //timeV的子控件
    private let clockLabel = UILabel() //时钟图标
    private let firstL = UILabel() //学习时长
    private let secondL = UILabel()//时间
    private let sepLine = UIView()
    
    private let peopleLabel = UILabel() //人头图标
    private let thirdL = UILabel() //报名人数
    private let fourthL = UILabel()//人数
    
    private let dateLabel = UILabel() //期限图标
    private let fiveLabel = UILabel() //期限
    private let sixLabel = UILabel()//时间限制
    private let line2 = UIView()
    
    internal let bottomV = UIView()  //底部view
    var textHeight = CGFloat()
    
    // used to offset the overview webview content which is at the bottom
    // below the rest of the content
    internal let topContentInsets = ConstantInsetsSource(insets: UIEdgeInsetsZero, affectsScrollIndicators: false)
    var action: ((completion : () -> Void) -> Void)?
    //教授名字
    internal var professor = ""
    private var _loaded = Sink<()>()
    var loaded : Stream<()> {
        return _loaded
    }
    
    init(frame: CGRect, environment: Environment) {
        self.environment = environment
        
        super.init(frame: frame)
        self.textView = TZStackView(arrangedSubviews: [blurbLabel,moreLabel])
        self.moreBtn.titleLabel?.font = UIFont.systemFontOfSize(14)
        self.moreBtn.setTitle(Strings.allText, forState: UIControlState.Normal)
        self.moreBtn.setTitleColor(UIColor.init(red: 79/255.0, green: 193/255.0, blue: 233/255.0, alpha: 1.0), forState: UIControlState.Normal)//79  193 233
        self.moreBtn.addTarget(self, action: #selector(showOrHidden), forControlEvents: UIControlEvents.TouchUpInside)
        self.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        setup()
    }
    func setDetail() {
        
        //学习时长
        clockLabel.font = UIFont.init(name: "FontAwesome", size: 20)
        clockLabel.text = "\u{f017}"
        clockLabel.textColor = UIColor.init(RGBHex: 0xaab2bd, alpha: 1)
        timeV.addSubview(clockLabel)
        
        clockLabel.snp_makeConstraints { (make) in
            make.top.equalTo(timeV.snp_top).offset(18)
            make.left.equalTo(timeV.snp_left).offset(18)
        }
        
        firstL.text = Strings.studyTime
        firstL.textAlignment = NSTextAlignment.Center
        firstL.font = UIFont.systemFontOfSize(14)
        timeV.addSubview(firstL)
        
        firstL.snp_makeConstraints { (make) in
            make.centerY.equalTo(clockLabel.snp_centerY)
            make.left.equalTo(clockLabel.snp_right).offset(20)
            make.height.equalTo(48)
        }
        secondL.font = UIFont.systemFontOfSize(14)
        timeV.addSubview(secondL)
        
        secondL.snp_makeConstraints { (make) in
            make.centerY.equalTo(clockLabel.snp_centerY)
            make.left.equalTo(firstL.snp_right).offset(28)
            make.height.equalTo(48)
        }
        
        timeV.addSubview(sepLine)
        sepLine.backgroundColor = UIColor.init(RGBHex: 0xCCD1D9, alpha: 1.0)
        sepLine.snp_makeConstraints { (make) in
            make.top.equalTo(timeV.snp_top).offset(48)
            make.leading.equalTo(timeV.snp_leading).offset(6)
            make.trailing.equalTo(timeV.snp_trailing).offset(-6)
            make.height.equalTo(1)
        }
        
        //报名人数
        peopleLabel.font = UIFont.init(name: "FontAwesome", size: 20)
        peopleLabel.text = "\u{f007}"
        peopleLabel.textColor = UIColor.init(RGBHex: 0xaab2bd, alpha: 1)
        timeV.addSubview(peopleLabel)
        
        peopleLabel.snp_makeConstraints { (make) in
            make.top.equalTo(sepLine.snp_bottom).offset(13)
            make.left.equalTo(timeV.snp_left).offset(18)
        }
        
        thirdL.text = Strings.applicationNumber
        thirdL.font = UIFont.systemFontOfSize(14)
        timeV.addSubview(thirdL)
        
        thirdL.snp_makeConstraints { (make) in
            make.centerY.equalTo(peopleLabel.snp_centerY)
            make.left.equalTo(firstL.snp_left)
            make.height.equalTo(48)
        }
        
        fourthL.font = UIFont.systemFontOfSize(14)
        timeV.addSubview(fourthL)//人数
        
        fourthL.snp_makeConstraints { (make) in
            make.centerY.equalTo(peopleLabel.snp_centerY)
            make.left.equalTo(thirdL.snp_right).offset(28)
            make.height.equalTo(48)
        }
        
        line2.backgroundColor = UIColor.init(RGBHex: 0xCCD1D9, alpha: 1.0)
        timeV.addSubview(line2)
        
        line2.snp_makeConstraints { (make) in
            make.top.equalTo(timeV.snp_top).offset(96)
            make.leading.equalTo(timeV.snp_leading).offset(6)
            make.trailing.equalTo(timeV.snp_trailing).offset(-6)
            make.height.equalTo(1)
        }
        
        //学习期限
        dateLabel.font = UIFont.init(name: "FontAwesome", size: 20)
        dateLabel.text = "\u{f133}"
        dateLabel.textColor = UIColor.init(RGBHex: 0xaab2bd, alpha: 1)
        timeV.addSubview(dateLabel)
        
        dateLabel.snp_makeConstraints { (make) in
            make.top.equalTo(line2.snp_bottom).offset(13)
            make.left.equalTo(timeV.snp_left).offset(18)
        }
        
        fiveLabel.text = Strings.dateLimit
        fiveLabel.font = UIFont.systemFontOfSize(14)
        timeV.addSubview(fiveLabel)
        
        fiveLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(dateLabel.snp_centerY)
            make.left.equalTo(firstL.snp_left)
            make.height.equalTo(48)
        }
        
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.lineSpacing = 2
        let str1 = NSMutableAttributedString.init(string: "\(Strings.noLimit)\n", attributes: [NSFontAttributeName : UIFont.systemFontOfSize(14),NSForegroundColorAttributeName : UIColor.blackColor() ,NSParagraphStyleAttributeName : paragraph])
        let str2 = NSMutableAttributedString.init(string: Strings.enrollMessage, attributes: [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 12)!,NSForegroundColorAttributeName : OEXStyles.sharedStyles().baseColor9(),NSParagraphStyleAttributeName : paragraph])
        str1.appendAttributedString(str2)
        
        sixLabel.attributedText = str1
        sixLabel.numberOfLines = 0;
        sixLabel.lineBreakMode = .ByCharWrapping //以字符为单位换行
        timeV.addSubview(sixLabel)
        
        sixLabel.snp_makeConstraints { (make) in
            make.top.equalTo(line2.snp_bottom).offset(13)
            make.left.equalTo(fiveLabel.snp_right).offset(28)
            make.right.equalTo(timeV.snp_right).offset(-8)
        }
    }
    
    func setBottomCell() {
        //主讲教授cell
        let imgV02 = UIImageView.init(image: UIImage.init(named: "zhangjie"))
        secondCell.addSubview(imgV02)
        imgV02.snp_makeConstraints { (make) in
            make.centerY.equalTo(secondCell.snp_centerY)
            make.left.equalTo(secondCell).offset(18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        let label2 = UILabel();
        label2.textColor = UIColor.whiteColor()
        label2.font = UIFont.init(name: "FontAwesome", size: 20)
        label2.text = "\u{f19c}"
        secondCell.addSubview(label2);
        
        label2.snp_makeConstraints { (make) in
            make.center.equalTo(imgV02.snp_center)
        }
        
        let secondCellL = UILabel()
        secondCellL.text = Strings.mainProfessor
        secondCell.addSubview(secondCellL)
        secondCellL.snp_makeConstraints { (make) in
            make.centerY.equalTo(secondCell.snp_centerY)
            make.left.equalTo(imgV02.snp_right).offset(19)
            make.height.equalTo(24)
        }
        let arrowV2 = UIImageView.init(image: UIImage.init(named: "arrow"))
        secondCell.addSubview(arrowV2)
        arrowV2.snp_makeConstraints { (make) in
            make.centerY.equalTo(secondCell.snp_centerY)
            make.right.equalTo(secondCell).offset(-18)
            make.width.equalTo(9)
            make.height.equalTo(14)
        }
        
        //课程大纲cell
        let imgV03 = UIImageView.init(image: UIImage.init(named: "zhangjie"))
        thirdCell.addSubview(imgV03)
        imgV03.snp_makeConstraints { (make) in
            make.centerY.equalTo(thirdCell.snp_centerY)
            make.left.equalTo(thirdCell).offset(18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        let label3 = UILabel();
        label3.font = UIFont.init(name: "FontAwesome", size: 20)
        label3.text = "\u{f0ca}"
        label3.textColor = UIColor.whiteColor()
        thirdCell.addSubview(label3);
        label3.snp_makeConstraints { (make) in
            make.center.equalTo(imgV03.snp_center)
        }
        
        
        let thirdCellL = UILabel()
        thirdCellL.text = Strings.courseOutline
        thirdCell.addSubview(thirdCellL)
        thirdCellL.snp_makeConstraints { (make) in
            make.centerY.equalTo(thirdCell.snp_centerY)
            make.left.equalTo(imgV02.snp_right).offset(19)
            make.height.equalTo(24)
        }
        
        let arrowV3 = UIImageView.init(image: UIImage.init(named: "arrow"))
        thirdCell.addSubview(arrowV3)
        arrowV3.snp_makeConstraints { (make) in
            make.centerY.equalTo(thirdCell.snp_centerY)
            make.right.equalTo(thirdCell).offset(-18)
            make.width.equalTo(9)
            make.height.equalTo(14)
        }
        
        //学员评价cell
        let imgV04 = UIImageView.init(image: UIImage.init(named: "zhangjie"))
        fourthCell.addSubview(imgV04)
        imgV04.snp_makeConstraints { (make) in
            make.centerY.equalTo(fourthCell.snp_centerY)
            make.left.equalTo(fourthCell).offset(18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        let label4 = UILabel();
        label4.font = UIFont.init(name: "FontAwesome", size: 20)
        label4.text = "\u{f040}"
        label4.textColor = UIColor.whiteColor()
        fourthCell.addSubview(label4);
        label4.snp_makeConstraints { (make) in
            make.center.equalTo(imgV04.snp_center)
        }
        
        let fourthL = UILabel()
        fourthL.text = Strings.studentComment
        fourthCell.addSubview(fourthL)
        fourthL.snp_makeConstraints { (make) in
            make.centerY.equalTo(fourthCell.snp_centerY)
            make.left.equalTo(imgV02.snp_right).offset(19)
            make.height.equalTo(24)
        }
        
        let arrowV4 = UIImageView.init(image: UIImage.init(named: "arrow"))
        fourthCell.addSubview(arrowV4)
        
        arrowV4.snp_makeConstraints { (make) in
            make.centerY.equalTo(fourthCell.snp_centerY)
            make.right.equalTo(fourthCell).offset(-18)
            make.width.equalTo(9)
            make.height.equalTo(14)
        }
        
        // 班级cell
        let imgV05 = UIImageView.init(image: UIImage.init(named: "zhangjie"))
        fivethCell.addSubview(imgV05)
        
        imgV05.snp_makeConstraints { (make) in
            make.centerY.equalTo(fivethCell.snp_centerY)
            make.left.equalTo(fivethCell).offset(18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        let label5 = UILabel()
        label5.font = UIFont.init(name: "FontAwesome", size: 20)
        label5.text = "\u{f0c0}"
        label5.textColor = UIColor.whiteColor()
        fivethCell.addSubview(label5);
        
        label5.snp_makeConstraints { (make) in
            make.center.equalTo(imgV05.snp_center)
        }
        
        let fiveLabel = UILabel()
        fiveLabel.text = Strings.classTitle
        fivethCell.addSubview(fiveLabel)
        
        fiveLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(fivethCell.snp_centerY)
            make.left.equalTo(imgV02.snp_right).offset(19)
            make.height.equalTo(24)
        }
        let arrowV5 = UIImageView.init(image: UIImage.init(named: "arrow"))
        fivethCell.addSubview(arrowV5)
        
        arrowV5.snp_makeConstraints { (make) in
            make.centerY.equalTo(fivethCell.snp_centerY)
            make.right.equalTo(fivethCell).offset(-18)
            make.width.equalTo(9)
            make.height.equalTo(14)
        }
        
        // 助教cell
        let imgV06 = UIImageView.init(image: UIImage.init(named: ""))
        sixthCell.addSubview(imgV06)
        
        imgV06.snp_makeConstraints { (make) in
            make.centerY.equalTo(sixthCell.snp_centerY)
            make.left.equalTo(sixthCell).offset(18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        let label6 = UILabel()
        label6.backgroundColor = OEXStyles.sharedStyles().baseColor2()
        label6.font = UIFont.init(name: "FontAwesome", size: 20)
        label6.text = "\u{f0c0}"
        label6.textColor = UIColor.whiteColor()
        label6.textAlignment = .Center
        label6.layer.masksToBounds = true
        label6.layer.cornerRadius = 6
        sixthCell.addSubview(label6);
        
        label6.snp_makeConstraints { (make) in
            make.center.equalTo(imgV06.snp_center)
            make.size.equalTo(CGSizeMake(30, 30))
        }
        
        let sixLabel = UILabel()
        sixLabel.text = Strings.teachAssistant
        sixthCell.addSubview(sixLabel)
        
        sixLabel.snp_makeConstraints { (make) in
            make.centerY.equalTo(sixthCell.snp_centerY)
            make.left.equalTo(imgV02.snp_right).offset(19)
            make.height.equalTo(24)
        }
        
        let arrowV6 = UIImageView.init(image: UIImage.init(named: "arrow"))
        sixthCell.addSubview(arrowV6)
        
        arrowV6.snp_makeConstraints { (make) in
            make.centerY.equalTo(sixthCell.snp_centerY)
            make.right.equalTo(sixthCell).offset(-18)
            make.width.equalTo(9)
            make.height.equalTo(14)
        }
    }
    //点击全文按钮
    func showOrHidden() {
        self.moreLabel.hidden = !self.moreLabel.hidden
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(descriptionView)
        addSubview(myScrollV)
        descriptionView.addSubview(topContainer)
        setUpScrollView()
        myScrollV.addSubview(courseCard)//课程卡片
        
        myScrollV.addSubview(textView)
        myScrollV.addSubview(moreBtn)//更多"全文"按钮
        myScrollV.addSubview(actionButton)//加入课程
        myScrollV.addSubview(giveLabel)//赠送宝典
        myScrollV.addSubview(timeV)//时长，报名人数
        myScrollV.addSubview(bottomV)
        
        bottomV.addSubview(secondCell)//第二个cell
        bottomV.addSubview(thirdCell)//第三个cell
        bottomV.addSubview(fourthCell)//第四个cell
        bottomV.addSubview(fivethCell)//课室cell
        bottomV.addSubview(sixthCell) //助教cell
        
        descriptionView.snp_makeConstraints {make in
            make.edges.equalTo(self)
        }
        myScrollV.snp_makeConstraints { (make) in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.width.equalTo(width)
            make.height.equalTo(self)
        }
        courseCard.snp_makeConstraints { (make) in
            make.top.equalTo(myScrollV).offset(16)
            make.leading.equalTo(myScrollV).offset(18)
            make.width.equalTo(width - 36)
            make.height.equalTo((width - 36) / 1.77)
        }
        textView.snp_makeConstraints { (make) in
            make.top.equalTo(courseCard.snp_bottom).offset(16)
            make.leading.equalTo(self).offset(24)
            make.trailing.equalTo(self).offset(-24)
        }
        textView.axis = .Vertical
        textView.alignment = .Fill
        
        moreBtn.snp_makeConstraints { (make) in
            make.top.equalTo(moreLabel.snp_bottom)
            make.leading.equalTo(myScrollV).offset(18)
        }
        
        //时长，报名人数
        let str1 = Strings.enrollMessage
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.lineSpacing = 2
        let size = str1.boundingRectWithSize(CGSizeMake(TDScreenWidth - 180, TDScreenHeight), options:[.UsesLineFragmentOrigin, .UsesFontLeading] , attributes: [NSFontAttributeName : UIFont.init(name: "OpenSans", size: 12)! , NSParagraphStyleAttributeName : paragraph], context: nil).size
        textHeight = size.height
        timeV.snp_makeConstraints { (make) in
            make.top.equalTo(moreBtn.snp_bottom).offset(14)
            make.leading.equalTo(self).offset(18)
            make.trailing.equalTo(self).offset(-18)
            make.height.equalTo(144 + size.height)
        }
        
        actionButton.snp_makeConstraints { (make) in
            make.top.equalTo(timeV.snp_bottom).offset(16)
            make.leading.equalTo(self).offset(18)
            make.trailing.equalTo(self).offset(-18)
            make.height.equalTo(42)
        }
        
        giveLabel.font = UIFont.init(name: "OpenSans", size: 14)
        giveLabel.numberOfLines = 0
        giveLabel.textColor = OEXStyles.sharedStyles().baseColor4()
        giveLabel.textAlignment = .Center
        giveLabel.snp_makeConstraints { (make) in
            make.top.equalTo(actionButton.snp_bottom).offset(8)
            make.leading.equalTo(self).offset(8)
            make.trailing.equalTo(self).offset(-8)
        }
        
        bottomV.snp_makeConstraints { (make) in
            make.top.equalTo(giveLabel.snp_bottom).offset(16)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(340)
        }
        
        secondCell.snp_makeConstraints { (make) in
            make.top.equalTo(bottomV).offset(20)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(60)
        }
        thirdCell.snp_makeConstraints { (make) in
            make.top.equalTo(secondCell.snp_bottom).offset(-1)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(60)
        }
        fourthCell.snp_makeConstraints { (make) in
            make.top.equalTo(thirdCell.snp_bottom).offset(-1)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(60)
        }
        
        fivethCell.snp_makeConstraints { (make) in
            make.top.equalTo(fourthCell.snp_bottom).offset(-1)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(60)
        }
        
        sixthCell.snp_makeConstraints { (make) in
            make.top.equalTo(fivethCell.snp_bottom).offset(-1)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(60)
        }
        
        var i : NSInteger = 0
        for cell in bottomV.subviews {
            i += 1
            cell.tag = i
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.init(RGBHex: 0xe6e9ed, alpha: 1).CGColor
        }
        
        blurbLabel.numberOfLines = 0
        moreLabel.numberOfLines = 0 //更多课程介绍文本
        
        textView.layoutMarginsRelativeArrangement = true
        textView.layoutMargins = UIEdgeInsetsMake(0, margin, 0, margin)
        textView.spacing = margin
        
        actionButton.oex_addAction({[weak self] _ in
            self?.actionButton.showProgress = true
            self?.action?( completion: { self?.actionButton.showProgress = false } )
            }, forEvents: .TouchUpInside)
        
        myScrollV.decelerationRate = UIScrollViewDecelerationRateNormal
        
        descriptionView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        descriptionView.delegate = self
        descriptionView.scrollView.bounces = false
        descriptionView.scrollView.scrollEnabled = true
        descriptionView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        playButton.setImage(Icon.CourseVideoPlay.imageWithFontSize(60), forState: .Normal)
        playButton.tintColor = OEXStyles.sharedStyles().neutralWhite()
        playButton.layer.shadowOpacity = 0.5
        playButton.layer.shadowRadius = 3
        playButton.layer.shadowOffset = CGSizeZero
        
        courseCard.addCenteredOverlay(playButton)
        
        setDetail() //具体布局设置
        setBottomCell() //设置底部cell内容
    }
    
    func setUpScrollView() {
        myScrollV.backgroundColor = UIColor.whiteColor()
        bottomV.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        timeV.backgroundColor = OEXStyles.sharedStyles().baseColor5()
        timeV.layer.cornerRadius = 4
        timeV.layer.borderWidth = 1
        timeV.layer.borderColor = OEXStyles.sharedStyles().baseColor7().CGColor
        
        secondCell.backgroundColor = UIColor.whiteColor()
        thirdCell.backgroundColor = UIColor.whiteColor()
        fourthCell.backgroundColor = UIColor.whiteColor()
        fivethCell.backgroundColor = UIColor.whiteColor()
        sixthCell.backgroundColor = UIColor.whiteColor()
        
        actionButton.backgroundColor = OEXStyles.sharedStyles().baseColor1()
        actionButton.layer.cornerRadius = 4.0;
    }
    private var blurbStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    private var moreLStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    private var descriptionHeaderStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Bold, size: .Large, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private func fieldSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        view.snp_makeConstraints {make in
            make.height.equalTo(OEXStyles.dividerSize())
        }
        
        return view
    }
    
    //课程详情
    var blurbText : String? {
        didSet {
            if let blurb = blurbText where !blurb.isEmpty {
                let blurbFont = [NSFontAttributeName: UIFont.systemFontOfSize(14),NSForegroundColorAttributeName:OEXStyles.sharedStyles().neutralXDark()]
                //// 原始的               self.blurbLabel.attributedText = blurbStyle.attributedStringWithText(blurb)
                let blurbAtt = NSMutableAttributedString(string: blurb, attributes: blurbFont)
                self.blurbLabel.attributedText = blurbAtt
                self.blurbLabel.hidden = false
            }
            else {
                self.blurbLabel.hidden = true
            }
        }
        
    }
    
    //更多课程
    var moreText : String? {
        didSet {
            if let moreL = moreText where !moreL.isEmpty{
                self.moreLabel.attributedText = moreLStyle.attributedStringWithText(moreL)
                self.moreLabel.hidden = true
            } else{
                self.moreLabel.hidden = true
                self.moreBtn.hidden = true;
                timeV.snp_remakeConstraints(closure: { (make) in
                    make.top.equalTo(courseCard.snp_bottom).offset(14)
                    make.leading.equalTo(self).offset(18)
                    make.trailing.equalTo(self).offset(-18)
                    make.height.equalTo(144 + textHeight)
                })
            }
        }
    }
    
    var descriptionHTML : String? {
        didSet {
            guard let html = OEXStyles.sharedStyles().styleHTMLContent(descriptionHTML, stylesheet: "inline-content") else {
                self.descriptionView.loadHTMLString("", baseURL: environment.networkManager.baseURL)
                return
            }
            
            self.descriptionView.loadHTMLString(html, baseURL: environment.networkManager.baseURL)
        }
    }
    //    var secondText : String? {
    //        didSet {
    //            if  let secL = secondText where !secL.isEmpty {
    ////                let font = [NSFontAttributeName : UIFont.systemFontOfSize(14)]
    ////                let secLAtt = NSMutableAttributedString(string: secL, attributes: font)
    //                self.secondL.attributedText = moreLStyle.attributedStringWithText(secL)
    //            }
    //        }
    //    }
    private func viewForField(field : Field) -> UIView {
        let view = ChoiceLabel()
        view.titleText = field.name
        view.valueText = field.value
        view.icon = field.icon
        return view
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        webView.scrollView.contentOffset = CGPoint(x: 0, y: -webView.scrollView.contentInset.top)
        _loaded.send(())
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let URL = request.URL where navigationType != .Other {
            UIApplication.sharedApplication().openURL(URL)
            return false
        }
        return true
    }
    
    //马上加入/查看课程
    var actionText: String? {
        get {
            return self.actionButton.attributedTitleForState(.Normal)?.string
        }
        set {
            //            actionButton.applyButtonStyle(OEXStyles.sharedStyles().filledEmphasisButtonStyle, withTitle: newValue)
            actionButton.setTitle(newValue, forState: UIControlState.Normal)
            actionButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        }
    }
    
    var actionAttributeText : NSAttributedString {
        get {
            let str = self.actionButton.attributedTitleForState(.Normal)!
            return str
        }
        set {
            actionButton.setAttributedTitle(newValue, forState: .Normal)
        }
    }
}

extension CourseCatalogDetailView {
    
    private func fieldsForCourse(course : OEXCourse) -> [Field] {
        var result : [Field] = []
        if let effort = course.effort where !effort.isEmpty {
            //            result.append(Field(name: Strings.CourseDetail.effort, value: effort, icon: .CourseEffort))
        }
        if let endDate = course.end where !course.isStartDateOld {
            //            let date = OEXDateFormatting.formatAsMonthDayYearString(endDate)
            //            result.append(Field(name: Strings.CourseDetail.endDate, value: date, icon: .CourseEnd))
        }
        return result
    }
    //加载课程详情信息函数
    func applyCourse(course : OEXCourse) {
        CourseCardViewModel.onCourseCatalog(course).apply(courseCard, networkManager: self.environment.networkManager,type:1)//头部图片
        
        if course.professor_username != nil {
            self.professor = course.professor_username!//教授名字
        }
        self.blurbText = course.short_description
        
        self.moreText = course.moreDescription //更多课程
        if (course.give_coin?.floatValue)! > 0 {
            let coinStr = NSString(format: "%.2f", (course.give_coin?.floatValue)!)
            
            let baseTool = TDBaseToolModel.init()
            let startStr = baseTool.interceptStr(course.begin_at!)
            let endStr = baseTool.interceptStr(course.end_at!)
            let giveStr = baseTool.setDetailString(Strings.receiveMind(startdate: startStr, enddate: endStr, number: coinStr as String), withFont: 12, withColorStr: "#f6bb42")
            giveLabel.attributedText = giveStr;
        }
        
        self.descriptionHTML = course.overview_html
        //        let fields = fieldsForCourse(course)
        self.secondL.text = course.effort?.stringByAppendingString(Strings.studyHour)
        if ((course.effort?.containsString("约")) != nil) {
            let timeStr = NSMutableString.init(string: course.effort!)
            let time = timeStr.stringByReplacingOccurrencesOfString("约", withString:"\(Strings.aboutTime) ")
            self.secondL.text = String(time.stringByAppendingString(" \(Strings.studyHour)"))
        }
        
        if course.listen_count != nil {
            let timeStr : String = course.listen_count!.stringValue
            self.fourthL.text = timeStr.stringByAppendingString(Strings.numberStudent)
        } else {
            self.fourthL.text = "0\(Strings.numberStudent)"
        }
        
        //        self.playButton.hidden = course.courseVideoMediaInfo?.uri?.isEmpty ?? true
        self.playButton.hidden = course.intro_video_3rd_url!.isEmpty ?? true
        //        self.playButton.oex_removeAllActions()
        //        self.playButton.oex_addAction(
        //            {[weak self] _ in
        //                if let
        ////                    path = course.courseVideoMediaInfo?.uri,
        //                    path = course.intro_video_3rd_url,
        //                    url = NSURL(string: path, relativeToURL: self?.environment.networkManager.baseURL)
        //                {
        //                    UIApplication.sharedApplication().openURL(url)
        //                }
        //            }, forEvents: .TouchUpInside)
    }
}


