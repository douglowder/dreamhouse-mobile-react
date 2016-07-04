//
//  MultipeerServer.m
//  dreamhousetv
//
//  Created by Douglas Lowder on 6/30/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "MultipeerServer.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MultipeerServer() <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate>

@property (nonatomic, nullable, readwrite, strong) MCSession *session;
@property (nonatomic, nullable, readwrite, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, nullable, readwrite, strong) NSMutableArray *connectedPeers;
@property (nonatomic, nullable, readwrite, strong) MCNearbyServiceBrowser *nearbyServiceBrowser;

+ (MCPeerID*)myPeerId;

@end

@implementation MultipeerServer

- (id)init {
    return [self initWithServiceType:@"x-test-service"];
}

static MCPeerID *__peerId;
static dispatch_once_t onceToken;

+ (MCPeerID*)myPeerId {
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *peerIdData = [defaults objectForKey:@"peerId"];
        if(!peerIdData) {
            __peerId = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
            peerIdData = [NSKeyedArchiver archivedDataWithRootObject:__peerId];
            [defaults setObject:peerIdData forKey:@"peerId"];
            [defaults synchronize];
        } else {
            __peerId = [NSKeyedUnarchiver unarchiveObjectWithData:peerIdData];
        }
    });
    return __peerId;
}

- (MultipeerServer * _Nonnull)initWithServiceType:(NSString * _Nonnull)serviceType {
    if(self = [super init]) {
        self.serviceType = serviceType;
        
        self.session = [[MCSession alloc] initWithPeer:[MultipeerServer myPeerId]
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
        
        self.serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:[MultipeerServer myPeerId]
                                                                   discoveryInfo:nil
                                                                     serviceType:self.serviceType];
        self.serviceAdvertiser.delegate = self;

        self.nearbyServiceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:[MultipeerServer myPeerId]
                                                                     serviceType:self.serviceType];
        self.nearbyServiceBrowser.delegate = self;
        
        self.connectedPeers = [NSMutableArray array];

    }
    return self;
}

- (void)run {
    [self.serviceAdvertiser startAdvertisingPeer];
    [self.nearbyServiceBrowser startBrowsingForPeers];
}

- (void)stop {
    [self.serviceAdvertiser stopAdvertisingPeer];
    [self.nearbyServiceBrowser stopBrowsingForPeers];
}

- (void)sendDataToPeers:(NSData *)data {
    NSError *error = nil;
    [self.session sendData:data toPeers:self.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    if(error) {
        NSLog(@"Error in sending data to peers: %@",[error description]);
    }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate Methods

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData*)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    
    NSLog(@"Received invitation from peer: %@",[peerID description]);
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        invitationHandler(YES, _session);
    });
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"Did not start advertising for peers: %@",[error description]);
}

#pragma mark - MCNearbyServiceBrowserDelegate methods

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"Found peer: %@",[peerID description]);
    if([MultipeerServer myPeerId].hash <= peerID.hash) {
        return;
    }
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.nearbyServiceBrowser invitePeer:peerID toSession:self.session withContext:nil timeout:15.0];
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"Lost peer: %@",[peerID description]);
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"Did not start browsing for peers: %@",[error description]);
}



#pragma mark - MCSessionDelegate Methods

- (void)dispatchPeersAreConnected {
    __weak MultipeerServer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate peersAreConnected];
    });
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    switch (state) {
        case MCSessionStateConnected:
            NSLog(@"Peer is connected: %@",[peerID description]);
            [self.connectedPeers addObject:peerID];
            [self dispatchPeersAreConnected];
            break;
        case MCSessionStateConnecting:
            NSLog(@"Peer is connecting: %@",[peerID description]);
            break;
        case MCSessionStateNotConnected:
            NSLog(@"Peer is not connected: %@",[peerID description]);
            [self.connectedPeers removeObject:peerID];
            break;
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSLog(@"Received data from peer: %@",[peerID description]);
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Data: %@",dataString);
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
}


@end
