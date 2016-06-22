//
//  AuthenticationPersistenceUtils.m
//  dreamhouse
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "AuthenticationPersistenceUtils.h"
#import "AppConstants.h"

#import <SalesforceRestAPI/SalesforceRestAPI.h>

static NSString * const kSavedCredentialsPreference = @"savedcredentials_preference";
static NSString * const kSavedUserInfoPreference = @"saveduserinfo_preference";

@implementation AuthenticationPersistenceUtils

+ (SFOAuthCredentials*)createCredentialsWithAccessToken:(NSString*)accessToken
                                              andUserId:(NSString*)userId
                                      andOrganizationId:(NSString*)organizationId
                                   andInstanceURLString:(NSString*)instanceURLString {
    
    SFOAuthCredentials *credentials = [[SFOAuthCredentials alloc] initWithIdentifier:@"dreamhouse"
                                                                            clientId:RemoteAccessConsumerKey
                                                                           encrypted:NO
                                                                         storageType:SFOAuthCredentialsStorageTypeNone];
    
    credentials.accessToken = accessToken;
    credentials.userId = userId;
    credentials.organizationId = organizationId;
    credentials.instanceUrl = [NSURL URLWithString:instanceURLString];
    
    return credentials;
}

+ (void)saveCredentials:(SFOAuthCredentials *)credentials {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedCredentials = [NSKeyedArchiver archivedDataWithRootObject:credentials];
    if(credentials) {
        
        [defaults setObject:encodedCredentials forKey:kSavedCredentialsPreference];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[@"accessToken"] = credentials.accessToken;
        userInfo[@"userId"] = credentials.userId;
        userInfo[@"organizationId"] = credentials.organizationId;
        [defaults setObject:userInfo forKey:kSavedUserInfoPreference];
        
    } else {
        [defaults removeObjectForKey:kSavedCredentialsPreference];
        [defaults removeObjectForKey:kSavedUserInfoPreference];
    }
    
    [defaults synchronize];
}

+ (SFOAuthCredentials*)loadCredentials {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedCredentials = [defaults objectForKey:kSavedCredentialsPreference];
    SFOAuthCredentials *credentials = (SFOAuthCredentials*)[NSKeyedUnarchiver unarchiveObjectWithData:encodedCredentials];
    
    NSDictionary *userInfo = [defaults objectForKey:kSavedUserInfoPreference];
    if(userInfo) {
        credentials.userId = userInfo[@"userId"];
        credentials.organizationId = userInfo[@"organizationId"];
        credentials.accessToken = userInfo[@"accessToken"];
    }
    
    return credentials;
}

+ (void)initializeAppWithCredentials:(SFOAuthCredentials *)credentials {
    SFUserAccount *user = [SFUserAccount new];
    user.credentials = credentials;
    
    SFOAuthCoordinator *newRestApiCoord = [[SFOAuthCoordinator alloc] initWithCredentials:user.credentials];
    newRestApiCoord.delegate = [SFAuthenticationManager sharedManager];
    
    [SFUserAccountManager sharedInstance].currentUser = user;
    [[SFRestAPI sharedInstance] setCoordinator:newRestApiCoord];
    
    return;
}


@end
