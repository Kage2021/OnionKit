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

uint16_t const kTorCheckPort = 443;
uint16_t const torControllerPort = 9150;

@interface torController  ()
@property (nonatomic, strong) GCDAsyncProxySocket *socket;
@property (nonatomic, strong) GCDAsyncProxySocket *testClientSocket;
@end


@implementation torController

-(id)init
{
    self = [super init];
    if (self)
    {
       
        
    
    
    }

    return self;
}


-(void)startController
{

    
    //Start TOR control port listener socket on 9150
   
    
    if ([OnionKit sharedInstance].isRunning)
    {
       
            NSError *error = NULL;
    
    
        self.socket = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [self.socket setProxyHost:@"127.0.0.1" port:torControllerPort version:GCDAsyncSocketSOCKSVersion5];
       
        
        
        //try to get TOR auth_cookie_file for authenticating controller
        NSData *rawCookie = [NSData dataWithContentsOfFile:([OnionKit sharedInstance]).cookieAuthFileLocation];
        
        //convert cookie to hex string as desired by TOR Controller
        NSString *hexCookie = [self stringToHex:(rawCookie)];
        
        //setup TOR Controller Authenticcation command
        NSMutableString *auth = [[NSMutableString alloc] init];
        [auth appendString:(@"AUTHENTICATE ")];
        [auth appendString:(@"%@", hexCookie)];
        [auth appendString:(@"\r\n")];
        NSString *authCommand = auth;
        NSLog(@"Auth Command looks like %@", authCommand);
        
        
        //connect to listener set up during init on 9150
        [self.socket connectToHost:@"127.0.0.1" onPort:torControllerPort withTimeout:(-5) error:&error];
        if (error)
        {
            NSLog(@"Connection error: %@", error.userInfo);
            error = NULL;
        }
        //Authenticate with that bitch
        [self.socket writeData:([authCommand dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]) withTimeout:-1 tag:9150];
                
        [self.socket readDataWithTimeout:-1 tag:9152];
        error = NULL;                }
        
    
    
    

    
}

-(void)controllerDidAuthenticate
{
    self.controllerUp = YES;
    self.controllerStatus = @"Controller Authenticated. Testing Client Functionality";
    //can or should I secure this connection?
    
    [self testClient];
}

-(void)testClient
{
    
   self.testClientSocket  = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.testClientSocket setProxyHost:@"127.0.0.1" port:[OnionKit sharedInstance].port  version:GCDAsyncSocketSOCKSVersion5];

}

-(void)startTor
{
    [[OnionKit sharedInstance] start];
}

-(NSString *)stringToHex:(NSData *)String
{
    NSUInteger len = [String length];
    char * chars = (char *)[String bytes];
    NSMutableString * hexString = [[NSMutableString alloc] init];
    
    for (NSUInteger i = 0; i < len; i++)
    {
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
    }
    return hexString;
}

-(NSString *)stringFromHex:(NSString *)hexStr
{
    NSMutableData *stringData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0', '\0', '\0'};
    int i;
    for (i=0; i < [hexStr length] / 2; i++)
    {
        byte_chars[0] = [hexStr characterAtIndex:i*2];
        byte_chars[1] = [hexStr characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [stringData appendBytes:&whole_byte length:1];
    }
    return [[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding];
    
}

#pragma mark GCDAsyncSocketDelegate methods


- (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%@ connected to %@ on port %d", sock, host, port);
    [sock startTLS:nil];
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socket %@ disconnected, code %d: %@, %@", sock, err.code, err.userInfo, err.domain);
}

- (void) socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"socket secured: %@", sock);
    // NSString *requestString = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nhost: %@\r\n\r\n", kTorCheckHost];
    // NSData *data = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:1];
    // [sock writeData:data withTimeout:-1 tag:0];
    
}

- (void) socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"socket closed readstream: %@", sock);
}

- (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"did write data %@ with tag %ld", sock, tag);
    if (tag == 9150)
    {
        self.controllerStatus = [NSString stringWithFormat:@"Sent authentication to control port, awaiting response."];
        NSLog(@"sent authentication command to control port");
        [sock readDataWithTimeout:-5 tag:9150];
    }
    
    
    
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSString *authSuccess = @"250 OK";
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@ %ld did read data:\n%@\n", sock, tag, responseString);
    [sock readDataWithTimeout:-1 tag:2];
    if (responseString == authSuccess)
    {
        [self controllerDidAuthenticate];
    }
    
}

@end