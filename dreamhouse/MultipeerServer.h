//
//  MultipeerServer.h
//  dreamhousetv
//
//  Created by Douglas Lowder on 6/30/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MultipeerDelegate

- (void)peersAreConnected;

@end


@interface MultipeerServer : NSObject

@property(nonatomic, nullable, readwrite, copy) NSString *serviceType;
@property(nonatomic, nullable, readwrite, weak) NSObject<MultipeerDelegate> *delegate;

- (MultipeerServer * _Nonnull)initWithServiceType:( NSString * _Nonnull )serviceType;

- (void)run;
- (void)stop;

- (void)sendDataToPeers:(NSData * _Nonnull)data;

@end
