//
//  torController.m
//  OnionKit
//
//  Created by Kenneth Gregory on 8/9/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import "torController.h"
#import "GCDAsyncProxySocket.h"
#import "OnionKit.h"

uint16_t const torControllerPort = 9150;

@interface torController()
@property (nonatomic, strong) GCDAsyncProxySocket *controllerSocket;
@property (nonatomic, strong) GCDAsyncProxySocket *commandSocket;
@end


@implementation torController

- (id)init
{
    self = [super init];
    if (self) {
        
        
//Start TOR control port listener on 9150
        self.controllerSocket = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.controllerSocket setProxyHost:@"127.0.0.1" port:torControllerPort version:GCDAsyncSocketSOCKSVersion5];
        NSError *error = NULL;
        
        
        
        //try to get TOR auth_cookie_file for authenticating controller and setting up SSL settings
     
        NSString *cookie = [[NSString alloc] initWithContentsOfFile:([OnionKit sharedInstance].cookieAuthFileLocation) encoding:NSASCIIStringEncoding error:&error];
        if (error)
        {
            NSLog(@"Error initializing authcookie with cookie file: %@", error.userInfo);
            error = NULL;
        }
        
        
        //setup dictionary that will be read to controller in order to authenticate us with the controller
        NSDictionary *sslSettings = @{
                                      @"Authenticate" : cookie,
                                      };
        

   
//setup socket to send commands from
        
        
        [self.controllerSocket startTLS:sslSettings];
        [self.controllerSocket connectToHost:@"127.0.0.1" onPort:torControllerPort withTimeout:(-5) error:&error];
        if (error) {
            NSLog(@"Error connecting to host %@", error.userInfo);
        }
    

        
// set up listener socket for 250 verification. If received, fanfare and bells, hold connection open somehow. Start reading statuses an from TOR to ensure client functionality and start relay setup.
        
    }
    return self;
}







#pragma mark GCDAsyncSocketDelegate methods


-(void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    

    NSLog(@"%@ connected to %@ on port %d", sock, host, port);
 
}







- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket %@ disconnected, code %d: %@, %@", sock, err.code, err.userInfo, err.domain);
}

- (void) socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"socket secured: %@", sock);

    
//This is how the test socket worked. After the socket was secured the request was written here and was written in the didreaddata below
    
    
    //   NSString *requestString = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nhost: %@\r\n\r\n", kTorCheckHost];
   // NSData *data = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:1];
    
    
    // [sock writeData:data withTimeout:-1 tag:0];
    
}



- (void) socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"socket closed readstream: %@", sock);
}

- (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"did write data %@ with tag %ld", sock, tag);
    
    
    
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@ %ld did read data:\n%@\n", sock, tag, responseString);
    [sock readDataWithTimeout:-1 tag:2];
}

@end


