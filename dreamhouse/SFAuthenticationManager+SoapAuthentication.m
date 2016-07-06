//
//  SFAuthenticationManager+SoapAuthentication.m
//  dreamhouse
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "SFAuthenticationManager+SoapAuthentication.h"
#import "AuthenticationPersistenceUtils.h"
#import "SFSoapAuthenticationViewController.h"
#import "SFPhoneAuthenticationViewController.h"
#import "AppDelegate.h"

@implementation SFAuthenticationManager(SoapAuthentication)


- (BOOL)loginWithCompletion:(SFOAuthFlowSuccessCallbackBlock)completionBlock failure:(SFOAuthFlowFailureCallbackBlock)failureBlock {
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loginWithCompletion:completionBlock failure:failureBlock];
        });
        return YES;
    }
    
    SFOAuthCredentials *credentials = [AuthenticationPersistenceUtils loadCredentials];
    if(credentials) {
        [AuthenticationPersistenceUtils initializeAppWithCredentials:credentials];
        SFOAuthInfo *info = [[SFOAuthInfo alloc] initWithAuthType:SFOAuthTypeUnknown];
        completionBlock(info);
        return YES;
    }
    
#if TARGET_OS_TV
    //SFPhoneAuthenticationViewController *vc = [[SFPhoneAuthenticationViewController alloc] initWithNibName:@"SFPhoneAuthenticationViewController" bundle:nil];
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

- (void)logout {
    [AuthenticationPersistenceUtils saveCredentials:nil];
    [self logoutUser:[SFUserAccountManager sharedInstance].currentUser];
}

@end
