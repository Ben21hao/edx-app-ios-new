//
//  OEXLoginViewController.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;

#import "OEXLoginViewController.h"
#import "TDRegisterViewController.h"
#import "TDResetPasswordViewController.h"

#import "edX-Swift.h"

#import <Masonry/Masonry.h>

#import "NSString+OEXValidation.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAnalytics.h"
#import "OEXAppDelegate.h"
#import "OEXCustomButton.h"
#import "OEXCustomLabel.h"
#import "OEXAuthentication.h"
#import "OEXFBSocial.h"
#import "OEXExternalAuthOptionsView.h"
#import "OEXFacebookAuthProvider.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleAuthProvider.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkUtility.h"
#import "OEXSession.h"
#import "OEXUserDetails.h"
#import "OEXUserLicenseAgreementViewController.h"
#import "Reachability.h"
#import "OEXStyles.h"

#define USER_LOGIN_NAME @"User_Login_Name_New"
#define USER_LOGIN_PASSWORD @"User_Login_Password_New"

@interface OEXLoginViewController () <UIAlertViewDelegate>
{
    CGPoint originalOffset;     // store the offset of the scrollview.
    UITextField* activeField;   // assign textfield object which is in active state.

}
@property (nonatomic, strong) NSString* str_ForgotEmail;
@property (nonatomic, strong) NSString* signInID;
@property (nonatomic, strong) NSString* signInPassword;
@property (nonatomic, assign) BOOL reachable;
@property (weak, nonatomic, nullable) IBOutlet UIWebView* webview_EULA;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_OpenEULA;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_SeparatorEULA;
@property (strong, nonatomic) IBOutlet UIView* externalAuthContainer;
@property (weak, nonatomic, nullable) IBOutlet OEXCustomLabel* lbl_OrSignIn;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorLeft;
@property(nonatomic, strong) IBOutlet UIImageView* seperatorRight;
// For Login Design change
// Manage on Constraints
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_MapTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_UsernameTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_PasswordTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_ForgotTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_SignInTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_SignTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_separatorTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_BySigningTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_EULATop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_UserGreyTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_PassGreyTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_LeftSepTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_RightSepTop;
@property (weak, nonatomic, nullable) IBOutlet NSLayoutConstraint* constraint_ActivityIndTop;

@property (weak, nonatomic, nullable) IBOutlet UITextField* tf_EmailID;
@property (weak, nonatomic, nullable) IBOutlet UITextField* tf_Password;
@property (weak, nonatomic) IBOutlet UIButton *eyesButton;
@property (weak, nonatomic) IBOutlet UIImageView *passwordBgView;
@property (weak, nonatomic) IBOutlet UIImageView *acountBgView;

@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_TroubleLogging;
@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_Login;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;

@property (weak, nonatomic, nullable) IBOutlet UIScrollView* scroll_Main;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Map;
@property (weak, nonatomic, nullable) IBOutlet UIImageView* img_Logo;
@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Redirect;
@property (weak, nonatomic, nullable) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;

@property (nonatomic, assign) id <OEXExternalAuthProvider> authProvider;

@end

@implementation OEXLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNavigationBarStye];
    [self setViewConstrainStye];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //Analytics Screen record
    [[OEXAnalytics sharedAnalytics] trackScreenWithName:@"Login"];
    
    OEXAppDelegate* appD = (OEXAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.reachable = [appD.reachability isReachable];
    
    //EULA
    [self hideEULA:YES];
    
    [self addNotificationCenter];
    
    //Tap to dismiss keyboard
    [self.view setUserInteractionEnabled:YES];
    self.view.exclusiveTouch = YES;
    UIGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToDismiss)];
    [self.view addGestureRecognizer:tapGesture];
    
    //To set all the components tot default property
    [self layoutSubviews];
    [self setToDefaultProperties];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view setUserInteractionEnabled:NO];
}

- (void)layoutSubviews {
    
    if(IS_IPHONE_4) {
        self.constraint_MapTop.constant = 70;
        self.constraint_UsernameTop.constant = 20;
        self.constraint_UserGreyTop.constant = 20;
        self.constraint_PasswordTop.constant = 8;
        self.constraint_PassGreyTop.constant = 8;
        self.constraint_ForgotTop.constant = 8;
        self.constraint_SignInTop.constant = 13;
        self.constraint_ActivityIndTop.constant = 43;
        self.constraint_SignTop.constant = 9;
        
        if([self isGoogleEnabled] || [self isFacebookEnabled]) {
            self.constraint_LeftSepTop.constant = 18;
            self.constraint_RightSepTop.constant = 18;
            self.constraint_BySigningTop.constant = 69;
            self.constraint_EULATop.constant = 73;
        }
        else {
            self.constraint_LeftSepTop.constant = 18;
            self.constraint_RightSepTop.constant = 18;
            self.constraint_BySigningTop.constant = 18;
            self.constraint_EULATop.constant = 23;
        }
    }
    else {
        self.constraint_MapTop.constant = 90;
        self.constraint_UsernameTop.constant = 25;
        self.constraint_UserGreyTop.constant = 25;
        self.constraint_PasswordTop.constant = 12;
        self.constraint_PassGreyTop.constant = 12;
        self.constraint_SignInTop.constant = 20;
        self.constraint_ActivityIndTop.constant = 55;
        self.constraint_SignTop.constant = 15;
        if([self isGoogleEnabled] || [self isFacebookEnabled]) {
            self.constraint_LeftSepTop.constant = 25;
            self.constraint_RightSepTop.constant = 25;
            self.constraint_BySigningTop.constant = 85;
            self.constraint_EULATop.constant = 88;
        }
        else {
            self.constraint_BySigningTop.constant = 25;
            self.constraint_EULATop.constant = 30;
        }
    }
}

#pragma mark - add notification
- (void)addNotificationCenter {
    // Scrolling on keyboard hide and show
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSignInToDefaultState:) name:UIApplicationDidBecomeActiveNotification object:nil];

}

#pragma mark - 导航栏
- (void)setNavigationBarStye {
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:18]
                                                                    };
    self.navigationItem.title = [Strings signInText];
    
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 68, 48)];
    rightButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, -16);
    rightButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    rightButton.titleLabel.textAlignment = NSTextAlignmentRight;
    rightButton.showsTouchWhenHighlighted = YES;
    [rightButton setTitle:NSLocalizedString(@"JUMP_OVER", nil) forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonAciton:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    
    
//        if (self.environment.config.isRegistrationEnabled) {
//            UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_cancel"] style:UIBarButtonItemStylePlain target:self action:@selector(navigateBack)];
//            closeButton.accessibilityLabel = [Strings close];
//            self.navigationItem.leftBarButtonItem = closeButton;
//        }
}

- (void)rightButtonAciton:(UIButton *)sender {
    [self.delegate loginViewControllerDidLogin:self];
}

//- (void)navigateBack {
//    [self dismissViewControllerAnimated:YES completion:nil];
//}


- (BOOL)isFacebookEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config facebookConfig].enabled;
}

- (BOOL)isGoogleEnabled {
    return ![OEXNetworkUtility isOnZeroRatedNetwork] && [self.environment.config googleConfig].enabled;
}

- (void)setExclusiveTouch {
    self.btn_OpenEULA.exclusiveTouch = YES;
    self.btn_Login.exclusiveTouch = YES;
    self.btn_TroubleLogging.exclusiveTouch = YES;
    self.view.multipleTouchEnabled = NO;
    self.view.exclusiveTouch = YES;
}

- (void)hideEULA:(BOOL)hide {
    //EULA
    [self.webview_EULA.scrollView setContentOffset:CGPointMake(0, 0)];
    self.webview_EULA.hidden = hide;
    self.img_SeparatorEULA.hidden = hide;
}

- (NSString*)signInButtonText {
    return [Strings signInText];
}

- (void)handleActivationDuringLogin {
    if(self.authProvider != nil) {
        [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
        
        [self.activityIndicator stopAnimating];
        [self.view setUserInteractionEnabled:YES];

        self.authProvider = nil;
    }
}

- (void)setSignInToDefaultState:(NSNotification*)notification {
    OEXFBSocial *facebookManager = [[OEXFBSocial alloc]init];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([self.authProvider isKindOfClass:[OEXGoogleAuthProvider class]] && ![[OEXGoogleSocial sharedInstance] handledOpenUrl]) {
        [[OEXGoogleSocial sharedInstance] clearHandler];
        [self handleActivationDuringLogin];
    }
    else if(![facebookManager isLogin] && [self.authProvider isKindOfClass:[OEXFacebookAuthProvider class]]) {
        [self handleActivationDuringLogin];
    }

    self.authProvider = nil;
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:NO];
}

- (void)setViewConstrainStye {
    
    NSMutableArray* providers = [[NSMutableArray alloc] init];
    if([self isGoogleEnabled]) {
        [providers addObject:[[OEXGoogleAuthProvider alloc] init]];
    }
    if([self isFacebookEnabled]) {
        [providers addObject:[[OEXFacebookAuthProvider alloc] init]];
    }
    
    __weak __typeof(self) owner = self;
    OEXExternalAuthOptionsView* externalAuthOptions = [[OEXExternalAuthOptionsView alloc] initWithFrame:self.externalAuthContainer.bounds providers:providers tapAction:^(id<OEXExternalAuthProvider> provider) {
        [owner externalLoginWithProvider:provider];
    }];
    [self.externalAuthContainer addSubview:externalAuthOptions];
    [externalAuthOptions mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.externalAuthContainer);
    }];
    
    [self.lbl_OrSignIn setText:[Strings noAccount]];
    [self.lbl_OrSignIn setTextColor:[UIColor colorWithHexString:colorHexStr8]];
    
    [self setExclusiveTouch];
    
    if ([self isRTL]) {
        [self.btn_TroubleLogging setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    }
    
    self.img_Logo.isAccessibilityElement = YES;
    self.img_Logo.accessibilityLabel = [[OEXConfig sharedConfig] platformName];
    
//    NSString* environmentName = self.environment.config.environmentName;
//    if(environmentName.length > 0) {
//        NSString* appVersion = [NSBundle mainBundle].oex_buildVersionString;
//        self.versionLabel.text = [Strings versionDisplayWithNumber:appVersion environment:environmentName];
//    } else {
//        self.versionLabel.text = @"";
//    }
    
//    NSString* appVersion = [NSBundle mainBundle].oex_buildVersionString;
//    self.versionLabel.text = [Strings versionDisplayWithNumber:appVersion];
    
    self.eyesButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:20.0];
    [self.eyesButton setTitle:@"\U0000f070" forState:UIControlStateNormal];
    [self.eyesButton setTitleColor:[UIColor colorWithHexString:colorHexStr8] forState:UIControlStateNormal];
    [self.eyesButton addTarget:self action:@selector(eyesButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.btn_Login.layer.cornerRadius = 4;
    self.btn_Login.backgroundColor = [UIColor colorWithHexString:colorHexStr1];
    self.registerButton.showsTouchWhenHighlighted = YES;
    [self.registerButton setTitle:NSLocalizedString(@"REGISTER", nil) forState:UIControlStateNormal];
    [self.registerButton setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    
    [self textField:self.tf_Password backgroundWithView:self.passwordBgView];
    [self textField:self.tf_EmailID backgroundWithView:self.acountBgView];

}

- (void)textField:(UITextField *)textField backgroundWithView:(UIImageView *)image  {
    image.backgroundColor = [UIColor colorWithHexString:colorHexStr5];
    image.layer.borderWidth = 0.5;
    image.layer.borderColor = [UIColor colorWithHexString:colorHexStr7].CGColor;
    image.layer.masksToBounds = YES;
    image.layer.cornerRadius = 4;
    
    textField.textColor = [UIColor colorWithHexString:colorHexStr9];
    textField.placeholder = [textField isEqual:_tf_EmailID] ? [Strings phoneOrEmail] : [Strings passwordPlaceholder];
    textField.text = @"";
    textField.accessibilityLabel = nil;
    textField.textAlignment = NSTextAlignmentNatural;
}

- (void)eyesButtonAction:(UIButton *)sender {
    
    self.tf_Password.secureTextEntry = !self.tf_Password.secureTextEntry;
    [self.eyesButton setTitle:self.tf_Password.secureTextEntry == YES ? @"\U0000f070" : @"\U0000f06e" forState:UIControlStateNormal];
}

- (void)setToDefaultProperties {
    
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.lbl_Redirect.text = [Strings redirectText];
    self.lbl_Redirect.isAccessibilityElement = NO;
    
    [self.btn_TroubleLogging setTitle:[Strings troubleInLoginButton] forState:UIControlStateNormal];
    [self.btn_TroubleLogging setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];
    
    [self.btn_OpenEULA setTitleColor:[UIColor colorWithHexString:colorHexStr1] forState:UIControlStateNormal];

    NSString *termsText = [Strings registrationAgreementButtonTitleWithPlatformName:self.environment.config.platformName];
    [self.btn_OpenEULA setTitle:termsText forState:UIControlStateNormal];
    self.btn_OpenEULA.titleLabel.adjustsFontSizeToFitWidth = YES;

    self.btn_OpenEULA.accessibilityTraits = UIAccessibilityTraitLink;
    self.btn_OpenEULA.accessibilityLabel = [NSString stringWithFormat:@"%@,%@",[Strings redirectText], termsText];
    
    [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];

    NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:USER_LOGIN_NAME];

    if(username) {
        _tf_EmailID.text = username;
        _tf_EmailID.accessibilityLabel = [Strings phoneOrEmail];
    }
}

- (void)reachabilityDidChange:(NSNotification*)notification {
    id <Reachability> reachability = [notification object];

    if([reachability isReachable]) {
        self.reachable = YES;
    }
    else {
        self.reachable = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view setUserInteractionEnabled:YES];
        });
        [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];

        [self.activityIndicator stopAnimating];
    }
}

#pragma mark IBActions
- (IBAction)openEULA:(id)sender {
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"Terms-and-Services" withExtension:@"htm"];
    OEXUserLicenseAgreementViewController* viewController = [[OEXUserLicenseAgreementViewController alloc] initWithContentURL:url];
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - 忘记密码
- (IBAction)troubleLoggingClicked:(id)sender {
    
    if(self.reachable) {
        [self.view setUserInteractionEnabled:NO];

        /* 弹框重置密码 */
//        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[Strings resetPasswordTitle]
//                                                        message:[Strings resetPasswordPopupText]
//                                                       delegate:self
//                                              cancelButtonTitle:[Strings cancel]
//                                              otherButtonTitles:[Strings ok], nil];
//
//        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//        UITextField* textfield = [alert textFieldAtIndex:0];
//        textfield.keyboardType = UIKeyboardTypeEmailAddress;
//
//        if([self.tf_EmailID.text length] > 0) {
//            UITextField* tf = [alert textFieldAtIndex:0];
//            [[alert textFieldAtIndex:0] setPlaceholder:[Strings emailAddressPrompt]];
//            tf.text = self.tf_EmailID.text;
//        }
//
//        alert.tag = 1001;
//        [alert show];
        
        [self resetPasswordAction];
    }
    else {
        // error
        
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessageTrouble]
                                     onViewController:self];
    }
}

- (void)resetPasswordAction {
    
    TDResetPasswordViewController *registerViewController = [[TDResetPasswordViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:registerViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - 注册
- (IBAction)registerButtonClicked:(UIButton *)sender {
    [self pushRegisterViewController];
}

- (void)pushRegisterViewController {
    
    TDRegisterViewController *registerViewController = [[TDRegisterViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:registerViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - 登录
- (IBAction)loginClicked:(id)sender {
    [self.view setUserInteractionEnabled:NO];
    TDBaseToolModel *baseTool = [[TDBaseToolModel alloc] init];
    
    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                              message:[Strings networkNotAvailableMessage]
                                     onViewController:self.navigationController
                                                            ];
        
        [self.view setUserInteractionEnabled:YES];

        return;
    }

    //Validation
    if([self.tf_EmailID.text length] == 0) { //账号为空
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterEmail]
                                                       onViewController:self.navigationController
                                                            ];

        [self.view setUserInteractionEnabled:YES];
    }
    else if([self.tf_Password.text length] == 0) { //密码为空
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                                                message:[Strings enterPassword]
                                                       onViewController:self.navigationController
                                                            ];

        [self.view setUserInteractionEnabled:YES];
        
    }
    else if (![baseTool isValidateMobile:self.tf_EmailID.text] && ![baseTool isValidateEmail:self.tf_EmailID.text]) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                              message:[Strings enterRightPhoneOrEmail]
                                     onViewController:self.navigationController
         ];
        
        [self.view setUserInteractionEnabled:YES];
    }
    else if([self.tf_Password.text length] < 6) { //密码少于6位
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                              message:[Strings morePassword]
                                     onViewController:self.navigationController
         ];
        
        [self.view setUserInteractionEnabled:YES];
        
    }
    else if([self.tf_Password.text length] > 30) {//密码多于30位
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                              message:[Strings lessPassword]
                                     onViewController:self.navigationController
         ];
        
        [self.view setUserInteractionEnabled:YES];
        
    }
    else {
        
        [self.view endEditing:YES];
        [self.view setUserInteractionEnabled:NO];
        [self.activityIndicator startAnimating];
        [self.btn_Login setTitle:[Strings signInButtonTextOnSignIn] forState:UIControlStateNormal];
        
        self.signInID = _tf_EmailID.text;
        self.signInPassword = _tf_Password.text;

        [OEXAuthentication requestTokenWithUser:_signInID password:_signInPassword completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
            
//            NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
//            NSLog(@"------>> %ld",(long)httpResp.statusCode);
            
            if (data == nil && response == nil && error == nil) {//未激活
                [self.view setUserInteractionEnabled:YES];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                [self.activityIndicator stopAnimating];
                [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NEED_ACTIVITY", nil)
                                                                    message:NSLocalizedString(@"SEND_EMAIL_ACTIVITY", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                alertView.tag = 2001;
                [alertView show];
            } else {
                [self handleLoginResponseWith:data response:response error:error];
            }
        }];
    }
}

- (void)handleLoginResponseWith:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error {
    
    [[OEXGoogleSocial sharedInstance] clearHandler];

    [self.view setUserInteractionEnabled:YES];

    if(!error) {
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
        NSLog(@"------>> %ld",(long)httpResp.statusCode);
        
        if(httpResp.statusCode == 200) {
            [self loginSuccessful];
        }
        else if(httpResp.statusCode == OEXHTTPStatusCode426UpgradeRequired) {
            [self showUpdateRequiredMessage];
        }
        else if(httpResp.statusCode >= 400 && httpResp.statusCode <= 500) {
            NSString* errorStr = [Strings invalidUsernamePassword];
            [self loginFailedWithErrorMessage:errorStr title:nil];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            });
        }
    }
    else {
        [self loginHandleLoginError:error];
    }
    self.authProvider = nil;
}

- (void)externalLoginWithProvider:(id <OEXExternalAuthProvider>)provider {
    self.authProvider = provider;
    if(!self.reachable) {
        [[UIAlertController alloc] showAlertWithTitle:[Strings networkNotAvailableTitle]
                                                                message:[Strings networkNotAvailableMessage]
                                                       onViewController:self.navigationController
                                                            ];
        self.authProvider = nil;
        return;
    }
    
    OEXURLRequestHandler handler = ^(NSData* data, NSHTTPURLResponse* response, NSError* error) {
        if(!response) {
            [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
            return;
        }
        self.authProvider = nil;
        
        [self handleLoginResponseWith:data response:response error:error];
    };
    
    [provider authorizeServiceFromController:self
                       requestingUserDetails:NO
                              withCompletion:^(NSString* accessToken, OEXRegisteringUserDetails* details, NSError* error) {
                                  if(accessToken) {
                                      [OEXAuthentication requestTokenWithProvider:provider externalToken:accessToken completion:handler];
                                  }
                                  else {
                                      handler(nil, nil, error);
                                  }
                              }];

    [self.view setUserInteractionEnabled:NO];
    [self.activityIndicator startAnimating];
    [self.btn_Login setTitle:[Strings signInButtonTextOnSignIn] forState:UIControlStateNormal];
}

- (void)loginHandleLoginError:(NSError*)error {
    if(error.code == -1003 || error.code == -1009 || error.code == -1005) {
        [self loginFailedWithErrorMessage:[Strings invalidUsernamePassword] title:nil];
    }
    else {
        if(error.code == 401) {
            [[OEXGoogleSocial sharedInstance] clearHandler];

            // MOB - 1110 - Social login error if the user's account is not linked with edX.
            if(self.authProvider != nil) {
                [self loginFailedWithServiceName: self.authProvider.displayName];
            }
        }
        else {
            [self loginFailedWithErrorMessage:[error localizedDescription] title: nil];
        }
    }
}

- (void)loginFailedWithServiceName:(NSString*)serviceName {
    NSString* platform = self.environment.config.platformName;
    NSString* destination = self.environment.config.platformDestinationName;
    NSString* title = [Strings serviceAccountNotAssociatedTitleWithService:serviceName platformName:platform];
    NSString* message = [Strings serviceAccountNotAssociatedMessageWithService:serviceName platformName:platform destinationName:destination];
    [self loginFailedWithErrorMessage:message title:title];
}

- (void)loginFailedWithErrorMessage:(NSString*)errorStr title:(NSString*)title {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if(title) {
        [[UIAlertController alloc] showAlertWithTitle:title
                                      message:errorStr
                             onViewController:self.navigationController];
    }
    else {
        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorLoginTitle]
                                      message:errorStr
                             onViewController:self.navigationController];
    }

    [self.activityIndicator stopAnimating];
    [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
    
    [self.view setUserInteractionEnabled:YES];

    [self tappedToDismiss];
}

- (void) showUpdateRequiredMessage {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activityIndicator stopAnimating];
    [self.btn_Login setTitle:[self signInButtonText] forState:UIControlStateNormal];
    
    [self.view setUserInteractionEnabled:YES];
    [self tappedToDismiss];
    
    UIAlertController *alertController = [[UIAlertController alloc] showAlertWithTitle:nil message:[VersionUpgrade outDatedLoginMessage] cancelButtonTitle:[Strings cancel] onViewController:self];
    
    [alertController addButtonWithTitle:[VersionUpgrade update] actionBlock:^(UIAlertAction * _Nonnull action) {
        NSURL *url = _environment.config.appUpgradeConfig.iOSAppStoreURL;
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
}

- (void)loginSuccessful {
    //set global auth

    if([_tf_EmailID.text length] > 0) {
        // Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];
        [[NSUserDefaults standardUserDefaults] setObject:_tf_EmailID.text forKey:USER_LOGIN_NAME];
        // Analytics User Login
        [[OEXAnalytics sharedAnalytics] trackUserLogin:[self.authProvider backendName] ?: @"Password"];
    }
    
    if (self.tf_Password.text.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.tf_Password.text forKey:USER_LOGIN_PASSWORD]; //登录密码
    }
    
    [self tappedToDismiss];
    [self.activityIndicator stopAnimating];

    //Launch next view
    [self didLogin];
}

- (void)didLogin {
    [self.delegate loginViewControllerDidLogin:self];
}

#pragma mark UI
- (void)tappedToDismiss {
    [_tf_EmailID resignFirstResponder];
    [_tf_Password resignFirstResponder];
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.view setUserInteractionEnabled:YES];

    if(alertView.tag == 1001) {
        UITextField* EmailtextField = [alertView textFieldAtIndex:0];

        if(buttonIndex == 1) {
            if([EmailtextField.text length] == 0 || ![EmailtextField.text oex_isValidEmailAddress]) {
                [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:[Strings invalidEmailMessage] onViewController:self.navigationController];
            }
            else {
                self.str_ForgotEmail = [[NSString alloc] init];

                self.str_ForgotEmail = EmailtextField.text;

                [self.view setUserInteractionEnabled:NO];

                [[UIAlertController alloc] showAlertWithTitle:[Strings resetPasswordTitle]
                                              message:[Strings waitingForResponse]
                                     onViewController:self.navigationController];
                [self resetPassword];
            }
        }
    } else if (alertView.tag == 2001) {
        if (buttonIndex == 1) {
            [self resendEmail];
        }
    }
}



#pragma mark - 重发邮件
- (void)resendEmail {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:self.tf_EmailID.text forKey:@"email"];
    
    NSString *url = [NSString stringWithFormat:@"%@/api/mobile/v0.5/account/resend_active_email/",ELITEU_URL];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self.view makeToast:NSLocalizedString(@"SEND_EMAIL_SUCCESS", nil) duration:1.08 position:CSToastPositionTop];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"重发邮件 -- %ld",(long)error.code);
    }];
}

- (void)resetPassword {
    [OEXAuthentication resetPasswordWithEmailId:self.str_ForgotEmail completionHandler:^(NSData* data, NSURLResponse* response, NSError* error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
                [self.view setUserInteractionEnabled:YES];

                if(!error) {
                    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
                    if(httpResp.statusCode == 200) {
                        [[[UIAlertView alloc] initWithTitle:[Strings resetPasswordConfirmationTitle]
                                                    message:[Strings resetPasswordConfirmationMessage]

                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:[Strings ok], nil] show];
                    }
                    else if(httpResp.statusCode <= 400 && httpResp.statusCode < 500) {
                        NSDictionary* dictionary = [NSJSONSerialization oex_JSONObjectWithData:data error:nil];
                        NSString* responseStr = [[dictionary objectForKey:@"email"] firstObject];
                        [[UIAlertController alloc]
                         showAlertWithTitle:[Strings floatingErrorTitle]
                                    message:responseStr onViewController:self.navigationController];
                    }
                    else if(httpResp.statusCode >= 500) {
                        NSString* responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [[UIAlertController alloc] showAlertWithTitle:[Strings floatingErrorTitle] message:responseStr onViewController:self.navigationController];
                        
                    }
                }
                else {
                    [[UIAlertController alloc]
                     showAlertWithTitle:[Strings floatingErrorTitle] message:[error localizedDescription] onViewController:self.navigationController];
                }
            });
    }];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* touch = [touches anyObject];
    if([[touch view] isKindOfClass:[UIButton class]]) {
        [self.view setUserInteractionEnabled:NO];
    }
}

#pragma mark TextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    if(textField == self.tf_EmailID) {
        [self.tf_Password becomeFirstResponder];
    }
    else {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.btn_Login);
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField isEqual:_tf_EmailID] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings phoneOrEmail];
    }
    else if([textField isEqual:_tf_EmailID] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    
    if ([textField isEqual:_tf_Password] && [textField.text isEqualToString:@""] && string.length > 0) {
        textField.accessibilityLabel = [Strings passwordPlaceholder];
    }
    else if([textField isEqual:_tf_Password] && [string isEqualToString:@""] && textField.text.length == 1) {
        textField.accessibilityLabel = nil;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField*)textField {
    activeField = textField;
}

#pragma mark - Scolling on Keyboard Hide/Show

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    // Calculating the height of the keyboard and the scrolling offset of the textfield
    // And scrolling on the calculated offset to make it visible

    NSDictionary* info = [aNotification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect toView:nil];
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scroll_Main.contentInset = contentInsets;
    self.scroll_Main.scrollIndicatorInsets = contentInsets;
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    aRect.size.height -= activeField.frame.size.height;
    CGPoint fieldOrigin = activeField.frame.origin;
    fieldOrigin.y -= self.scroll_Main.contentOffset.y;
    fieldOrigin = [self.view convertPoint:fieldOrigin toView:self.view.superview];
    originalOffset = self.scroll_Main.contentOffset;
    if(!CGRectContainsPoint(aRect, fieldOrigin) ) {
        [self.scroll_Main scrollRectToVisible:CGRectMake(activeField.frame.origin.x, activeField.frame.origin.y, activeField.frame.size.width, activeField.frame.size.height) animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scroll_Main.contentInset = contentInsets;
    self.scroll_Main.scrollIndicatorInsets = contentInsets;
    [self.scroll_Main setContentOffset:originalOffset animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView;
{
    if(scrollView == self.scroll_Main) {
        originalOffset = scrollView.contentOffset;
    }
}

- (BOOL)isRTL {
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [OEXStyles sharedStyles].standardStatusBarStyle;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
