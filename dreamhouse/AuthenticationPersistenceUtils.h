//
//  AuthenticationPersistenceUtils.h
//  dreamhouse
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SalesforceSDKCore/SalesforceSDKManager.h>

@interface AuthenticationPersistenceUtils : NSObject

+ (SFOAuthCredentials*)createCredentialsWithAccessToken:(NSString*)accessToken
                                              andUserId:(NSString*)userId
                                      andOrganizationId:(NSString*)organizationId
                                   andInstanceURLString:(NSString*)instanceURLString;

+ (void)saveCredentials:(SFOAuthCredentials*)credentials;

+ (SFOAuthCredentials*)loadCredentials;

+ (void)initializeAppWithCredentials:(SFOAuthCredentials*)credentials;

@end
