//
//  SFSoapAuthenticationViewController.h
//  dreamhouse
//
//  Created by Douglas Lowder on 6/15/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>

@interface SFSoapAuthenticationViewController : UIViewController

@property(nonatomic, nullable, readwrite, strong) IBOutlet UITextField *usernameField;
@property(nonatomic, nullable, readwrite, strong) IBOutlet UILabel *usernameLabel;

@property(nonatomic, nullable, readwrite, strong) IBOutlet UITextField *passwordField;
@property(nonatomic, nullable, readwrite, strong) IBOutlet UILabel *passwordLabel;

@property(nonatomic, nullable, readwrite, strong) IBOutlet UIButton *submitButton;

@property(nonatomic, nullable, readwrite, copy) SFOAuthFlowSuccessCallbackBlock completionBlock;
@property(nonatomic, nullable, readwrite, copy) SFOAuthFlowFailureCallbackBlock failureBlock;


- (IBAction)submitButtonPressed:(_Nullable id)sender;

@end
