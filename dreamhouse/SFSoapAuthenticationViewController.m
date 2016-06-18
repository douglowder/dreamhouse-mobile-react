//
//  SFSoapAuthenticationViewController.m
//  dreamhouse
//
//  Created by Douglas Lowder on 6/15/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "SFSoapAuthenticationViewController.h"
#import <SalesforceSDKCore/SFPushNotificationManager.h>
#import <SalesforceSDKCore/SFDefaultUserManagementViewController.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>
#import <SalesforceSDKCore/SFUserAccountManager.h>
#import <SalesforceSDKCore/SFLogger.h>
#import <SmartStore/SalesforceSDKManagerWithSmartStore.h>
#import <SalesforceRestAPI/SalesforceRestAPI.h>
#import <SalesforceSDKCore/SFUserAccountManager.h>

#import "AppDelegate.h"

static NSString * const RemoteAccessConsumerKey = @"3MVG9Iu66FKeHhINkB1l7xt7kR8czFcCTUhgoA8Ol2Ltf1eYHOU4SqQRSEitYFDUpqRWcoQ2.dBv_a1Dyu5xa";
static NSString * const OAuthRedirectURI        = @"testsfdc:///mobilesdk/detect/oauth/done";

static NSString * const kSaveUserPreference = @"saveuser_preference";
static NSString * const kSecurityTokenPreference = @"securitytoken_preference";
static NSString * const kPreviousUsernamePreference = @"previoususername_preference";

#pragma mark -
#pragma mark Category to override SFAuthenticationManager login code

@interface SFAuthenticationManager(SoapAuthentication)

- (BOOL)loginWithCompletion:(SFOAuthFlowSuccessCallbackBlock)completionBlock failure:(SFOAuthFlowFailureCallbackBlock)failureBlock;

@end

@implementation SFAuthenticationManager(SoapAuthentication)

- (BOOL)loginWithCompletion:(SFOAuthFlowSuccessCallbackBlock)completionBlock failure:(SFOAuthFlowFailureCallbackBlock)failureBlock {
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loginWithCompletion:completionBlock failure:failureBlock];
        });
        return YES;
    }

#if TARGET_OS_TV
    SFSoapAuthenticationViewController *vc = [[SFSoapAuthenticationViewController alloc] initWithNibName:@"SFSoapAuthenticationViewControllerTV" bundle:nil];
#else
    SFSoapAuthenticationViewController *vc = [[SFSoapAuthenticationViewController alloc] initWithNibName:@"SFSoapAuthenticationViewController" bundle:nil];
#endif
    
    vc.completionBlock = completionBlock;
    vc.failureBlock = failureBlock;
    
    
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.window.rootViewController = vc;
    [appDelegate.window makeKeyAndVisible];
    
    return YES;
    
}

@end

#pragma mark -
#pragma mark SOAP login view controller

@interface SFSoapAuthenticationViewController ()

@end

@implementation SFSoapAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Load previously used username if appropriate
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSNumber *saveUserPreference = [defaults objectForKey:kSaveUserPreference];
    
    // defaults to true if user has not set this yet
    BOOL saveUser = saveUserPreference ? [saveUserPreference boolValue] : YES;
    
    if(saveUser) {
        self.usernameField.text = [defaults valueForKey:kPreviousUsernamePreference];
    }

    
#if !TARGET_OS_TV
    // Lightning Design System styling for the view
    
    self.usernameField.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:12.0];
    self.usernameLabel.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:10.0];

    self.passwordField.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:12.0];
    self.passwordLabel.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:10.0];
    
    self.submitButton.backgroundColor = [UIColor colorWithRed:0.0 green:112.0/255.0 blue:210.0/255.0 alpha:1.0];
    self.submitButton.tintColor = [UIColor whiteColor];
    self.submitButton.layer.cornerRadius = 5.0;
#endif

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitButtonPressed:(id)sender {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    [self doSoapAuthenticationWithUsername:username andPassword:password];
}

- (NSString*)contentOfXMLTag:(NSString*)tagName inXMLString:(NSString*)string {
    NSString *openingTag = [NSString stringWithFormat:@"<%@>",tagName];
    NSString *closingTag = [NSString stringWithFormat:@"</%@>",tagName];
    NSRange range1 = [string rangeOfString:openingTag];
    NSRange range2 = [string rangeOfString:closingTag];
    if(range1.location == NSNotFound || range2.location == NSNotFound) {
        return nil;
    }
    
    NSString *returnValue = [string substringWithRange:NSMakeRange(range1.location + range1.length, range2.location - (range1.location + range1.length))];
    
    return returnValue;

}

- (void)doSoapAuthenticationWithUsername:(NSString*)username andPassword:(NSString*)password {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *securityToken = [defaults valueForKey:kSecurityTokenPreference];
    BOOL saveUser = [[defaults valueForKey:kSaveUserPreference] boolValue];
    if(saveUser) {
        [defaults setValue:username forKey:kPreviousUsernamePreference];
        [defaults synchronize];
    }
    
    NSString *requestDataString = [NSString stringWithFormat:@"\
                                   <env:Envelope xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" \
                                   xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" \
                                   xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"> \
                                   <env:Body>\
                                   <n1:login xmlns:n1=\"urn:partner.soap.sforce.com\">\
                                   <n1:username>%@</n1:username>\
                                   <n1:password>%@%@</n1:password>\
                                   </n1:login>\
                                   </env:Body>\
                                   </env:Envelope>",
                                   username,password,securityToken];
    
    NSURL *url = [NSURL URLWithString:@"https://login.salesforce.com/services/Soap/u/36.0"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSData dataWithBytes:[requestDataString cStringUsingEncoding:NSUTF8StringEncoding] length:[requestDataString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"login" forHTTPHeaderField:@"SOAPAction"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data,  NSError *error) {
                               
                               SFOAuthInfo *info = [[SFOAuthInfo alloc] initWithAuthType:SFOAuthTypeUnknown];

                               if(error) {
                                   NSLog(@"Authentication error: %@",[error description]);
                                   [self handleError:error withInfo:info];
                                   return;
                               }
                               
                               NSString *responseData = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                               
                               // Extract access token
                               
                               
                               NSString *accessToken = [self contentOfXMLTag:@"sessionId" inXMLString:responseData];
                               
                               if(!accessToken) {
                                   [self handleError:nil withInfo:info];
                               }
                               
                               NSString *instanceUrl = [self contentOfXMLTag:@"serverUrl" inXMLString:responseData];
                               
                               if(!instanceUrl) {
                                   [self handleError:nil withInfo:info];
                               }
                               
                               NSRange range = [instanceUrl rangeOfString:@"services"];
                               instanceUrl = [instanceUrl substringToIndex:range.location];
                               
                               NSString *organizationId = [self contentOfXMLTag:@"organizationId" inXMLString:responseData];
                               
                               NSString *userId = [self contentOfXMLTag:@"userId" inXMLString:responseData];
                               
                               SFUserAccount *user = [SFUserAccount new];
                               user.credentials = [[SFOAuthCredentials alloc] initWithIdentifier:@"dreamhouse"
                                                                                        clientId:RemoteAccessConsumerKey
                                                                                       encrypted:NO
                                                                                     storageType:SFOAuthCredentialsStorageTypeNone];
                               
                               user.credentials.accessToken = accessToken;
                               user.credentials.userId = userId;
                               user.credentials.organizationId = organizationId;
                               user.credentials.instanceUrl = [NSURL URLWithString:instanceUrl];
                               
                               
                               SFOAuthCoordinator *newRestApiCoord = [[SFOAuthCoordinator alloc] initWithCredentials:user.credentials];
                               newRestApiCoord.delegate = [SFAuthenticationManager sharedManager];
                               
                               [SFUserAccountManager sharedInstance].currentUser = user;
                               [[SFRestAPI sharedInstance] setCoordinator:newRestApiCoord];
                               
                               self.completionBlock(info);
                           }];
    

}

- (void)handleError:(NSError*)error withInfo:(SFOAuthInfo*)info {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleError:error withInfo:info];
        });
        return;
    }
    

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Login failed" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        self.failureBlock(info,error);
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
