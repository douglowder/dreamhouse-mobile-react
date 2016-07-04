//
//  SFPhoneAuthenticationViewController.m
//  dreamhousetv
//
//  Created by Douglas Lowder on 6/22/16.
//  Copyright © 2016 Salesforce. All rights reserved.
//

#import "SFPhoneAuthenticationViewController.h"
#import "MultipeerServer.h"

@interface SFPhoneAuthenticationViewController() <MultipeerDelegate>


@property(nonatomic, nullable, readwrite, strong) MultipeerServer *server;
@property(nonatomic, nullable, readwrite, assign) BOOL *serverIsRunning;


@end

@implementation SFPhoneAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.serverIsRunning = NO;
    self.server = [[MultipeerServer alloc] init];
    self.server.delegate = self;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)startStopButtonPressed:(id)sender {
    if(!self.serverIsRunning) {
        [self startService];
    } else {
        [self stopService];
    }
}


- (void)startService {
    [self.server run];
    self.serverIsRunning = YES;
    self.startStopButton.titleLabel.text = @"Stop";
}

- (void)stopService {
    [self.server stop];
    self.serverIsRunning = NO;
    self.startStopButton.titleLabel.text = @"Start";
}

- (void)peersAreConnected {
    NSString *s = @"test string from server";
    ;
    NSData *d = [NSData dataWithBytes:[s cStringUsingEncoding:NSUTF8StringEncoding]
                               length:[s lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    [self.server sendDataToPeers:d];
}


@end
