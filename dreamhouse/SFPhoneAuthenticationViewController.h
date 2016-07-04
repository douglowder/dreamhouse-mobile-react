//
//  SFPhoneAuthenticationViewController.h
//  dreamhousetv
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>

@interface SFPhoneAuthenticationViewController : UIViewController

@property(nonatomic, nullable, readwrite, strong) IBOutlet UILabel *instructionsLabel;
@property(nonatomic, nullable, readwrite, strong) IBOutlet UILabel *codeLabel;

@property(nonatomic, nullable, readwrite, strong) IBOutlet UIButton *startStopButton;

@property(nonatomic, nullable, readwrite, copy) SFOAuthFlowSuccessCallbackBlock completionBlock;
@property(nonatomic, nullable, readwrite, copy) SFOAuthFlowFailureCallbackBlock failureBlock;

- (IBAction)startStopButtonPressed:(_Nullable id)sender;

@end
