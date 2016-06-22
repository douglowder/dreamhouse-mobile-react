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
#import "AuthenticationPersistenceUtils.h"
#import "AppConstants.h"



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

#if TARGET_OS_TV
    CGFloat fieldFontSize = 36.0;
    CGFloat labelFontSize = 24.0;
#else
    CGFloat fieldFontSize = 12.0;
    CGFloat labelFontSize = 10.0;
#endif
    
    // Lightning Design System styling for the view
    UIColor *sfBlueColor = [UIColor colorWithRed:0.0 green:112.0/255.0 blue:210.0/255.0 alpha:1.0];
    UIColor *sfGreyColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.0];
    
    self.usernameField.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:fieldFontSize];
    self.usernameField.minimumFontSize = fieldFontSize;
    self.usernameField.layer.borderColor = [sfBlueColor CGColor];
    
    self.usernameLabel.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:labelFontSize];

    self.passwordField.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:fieldFontSize];
    self.passwordField.minimumFontSize = fieldFontSize;
    self.passwordField.layer.borderColor = [sfBlueColor CGColor];
    
    self.passwordLabel.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:labelFontSize];
    
#if TARGET_OS_TV
    //self.usernameField.backgroundColor = sfGreyColor;
    //self.passwordField.backgroundColor = sfGreyColor;
#endif
    
#if !TARGET_OS_TV
    self.submitButton.font = [UIFont fontWithName:@"SalesforceSans-Regular" size:labelFontSize];
#endif
    
    self.submitButton.backgroundColor = [UIColor colorWithRed:0.0 green:112.0/255.0 blue:210.0/255.0 alpha:1.0];
    self.submitButton.tintColor = [UIColor whiteColor];
    self.submitButton.layer.cornerRadius = 5.0;

    
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
                               
                               NSString *instanceUrlString = [self contentOfXMLTag:@"serverUrl" inXMLString:responseData];
                               
                               if(!instanceUrlString) {
                                   [self handleError:nil withInfo:info];
                               }
                               
                               NSRange range = [instanceUrlString rangeOfString:@"services"];
                               instanceUrlString = [instanceUrlString substringToIndex:range.location];
                               
                               NSString *organizationId = [self contentOfXMLTag:@"organizationId" inXMLString:responseData];
                               
                               NSString *userId = [self contentOfXMLTag:@"userId" inXMLString:responseData];
                               
                               
                               SFOAuthCredentials *credentials = [AuthenticationPersistenceUtils
                                                                  createCredentialsWithAccessToken:accessToken
                                                                  andUserId:userId
                                                                  andOrganizationId:organizationId
                                                                  andInstanceURLString:instanceUrlString];
                               
                               [AuthenticationPersistenceUtils saveCredentials:credentials];
                               
                               [AuthenticationPersistenceUtils initializeAppWithCredentials:credentials];
                               
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
