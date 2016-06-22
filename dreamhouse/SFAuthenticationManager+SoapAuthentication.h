//
//  SFAuthenticationManager+SoapAuthentication.h
//  dreamhouse
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>

#pragma mark -
#pragma mark Category to override SFAuthenticationManager login code

@interface SFAuthenticationManager(SoapAuthentication)


- (BOOL)loginWithCompletion:(SFOAuthFlowSuccessCallbackBlock)completionBlock failure:(SFOAuthFlowFailureCallbackBlock)failureBlock;

- (void)logout;

@end
