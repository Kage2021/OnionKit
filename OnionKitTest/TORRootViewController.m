//
//  TORRootViewController.m
//  OnionKit
//
//  Created by Christopher Ballinger on 11/19/13.
//  Copyright (c) 2013 ChatSecure. All rights reserved.
//

#import "TORRootViewController.h"
#import "GCDAsyncProxySocket.h"
#import "OnionKit.h"
#import "torController.h"

NSString * const kHITorManagerIsRunningKey = @"isRunning";
NSString * const CONNECTING_STRING = @"Connecting to Tor...";
NSString * const DISCONNECTING_STRING = @"Disconnecting from Tor...";
NSString * const DISCONNECTED_STRING = @"Disconnected from Tor";
NSString * const CONNECTED_STRING = @"Connected to Tor!";
NSString * const CONNECT_STRING = @"Connect";
NSString * const DISCONNECT_STRING = @"Disconnect";
NSString * const CANNOT_RECONNECT_STRING = @"Cannot Reconnect";
NSString * const TEST_STRING = @"Test";

NSString * const kTorCheckHost = @"check.torproject.org";
uint16_t const kTorCheckPort = 443;
uint16_t const torControllerPort = 9150;
torController *controller;

@interface TORRootViewController ()
@property (nonatomic, strong) GCDAsyncProxySocket *socket;
@end

@implementation TORRootViewController
@synthesize connectionStatusLabel, activityIndicatorView, connectButton, testButton;

- (void) dealloc {
   [[OnionKit sharedInstance] removeObserver:self forKeyPath:kOnionKitStartedNotification];
}


- (id)init
{
    self = [super init];
    if (self) {
        self.connectionStatusLabel = [[UILabel alloc] init];
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.connectButton addTarget:self action:@selector(connectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
        
        [[OnionKit sharedInstance] addObserver:self forKeyPath:kOnionKitStartedNotification options:NSKeyValueObservingOptionNew context:NULL];
        self.testButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.testButton addTarget:self action:@selector(testButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
       
    }
    return self;
}

- (void) testButtonPressed:(id)sender 
{
    [controller startController];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:connectionStatusLabel];
    [self.view addSubview:activityIndicatorView];
    [self.view addSubview:connectButton];
    [self.view addSubview:testButton];
    
    
    // setup label and button titles
    self.connectionStatusLabel.text = DISCONNECTED_STRING;
    self.connectionStatusLabel.textColor = [UIColor redColor];
    [self.connectButton setTitle:CONNECT_STRING forState:UIControlStateNormal];
    [self.testButton setTitle:TEST_STRING forState:UIControlStateNormal];
}




- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    
    // setup frames
    CGFloat padding = 20.0f;
    self.connectionStatusLabel.frame = CGRectMake(padding, padding, 200, 30);
    self.activityIndicatorView.frame = CGRectMake(connectionStatusLabel.frame.origin.x + connectionStatusLabel.frame.size.width + padding, padding, 30, 30);
    self.connectButton.frame = CGRectMake(padding, connectionStatusLabel.frame.origin.y + connectionStatusLabel.frame.size.height + padding, 150, 50);
    CGRect testButtonFrame = self.connectButton.frame;
    testButtonFrame.origin.y = self.connectButton.frame.origin.y + self.connectButton.frame.size.height + padding;
    self.testButton.frame = testButtonFrame;
}




- (void) connectButtonPressed:(id)sender {
    [self.activityIndicatorView startAnimating];
    if (!self.connectButton.enabled) {
        // do nothing if already connecting
        return;
    }
    self.connectButton.enabled = NO;
    self.connectionStatusLabel.textColor = [UIColor orangeColor];
    if (![OnionKit sharedInstance].isRunning) {
        self.connectionStatusLabel.text = CONNECTING_STRING;
       controller = [[torController alloc] init];
        [controller startTor];
    } else {
        self.connectionStatusLabel.text = DISCONNECTING_STRING;
        [[OnionKit sharedInstance  ] stop];
   }

}




- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:kOnionKitStartedNotification]) {
        BOOL isRunning = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isRunning) {
            self.connectionStatusLabel.text = CONNECTED_STRING;
            self.connectionStatusLabel.textColor = [UIColor greenColor];
            [self.connectButton setTitle:DISCONNECT_STRING forState:UIControlStateNormal];
            self.connectButton.enabled = YES;
        } else {
            self.connectionStatusLabel.text = DISCONNECTED_STRING;
            self.connectionStatusLabel.textColor = [UIColor redColor];
            [self.connectButton setTitle:CANNOT_RECONNECT_STRING forState:UIControlStateNormal];
            self.connectButton.enabled = NO; // Tor crashes if you disconnect and reconnect, so only allow connecting once.
        }
        [self.activityIndicatorView stopAnimating];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
