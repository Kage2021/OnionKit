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



NSString * const AUTH_SUCCESS = @"250";
NSString * const checkClientHost = @"check.torproject.org";

uint16_t const torControllerPort = 9150;
uint16_t const checkClientPort = 443;
uint16_t const checkClientPortLocal = 9050;


@interface torController  ()

@property (nonatomic, strong) GCDAsyncProxySocket *socket;
@property (nonatomic, strong) GCDAsyncProxySocket *testSocket;

@end





@implementation torController

-(id)init
{
    self = [super init];
    if (self)
    {
        self.socket = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.clientStat = NO;
    }

    return self;
}





-(void)startController
{
    self.checkTorReturnedIP = nil;
    
    
    
    if ([OnionKit sharedInstance].isRunning)
    {
        //test TOR client functionality. See if we can hit outside address check.torproject.org and determine what the site reports our IP as.
        self.testSocket = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *error = NULL;
        [self.testSocket setProxyHost:@"127.0.0.1" port:checkClientPortLocal version:GCDAsyncSocketSOCKSVersion5];
        if (error)
        {
            NSLog(@"Cannot verify client functionality. %@", error.userInfo);
        }
            error = NULL;
        [self.testSocket connectToHost:checkClientHost onPort:checkClientPort withTimeout:-5 error:&error];
    }

}        
        


-(void)authenticateController
{        NSError *error = NULL;    
    
    
    if ([OnionKit sharedInstance].isRunning)
    {
        if (self.clientStat == YES)
        {
            
            if (!(self.checkTorReturnedIP == nil))
            {
                
                
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
            
            
                //connect to listener set on 9150
                [self.socket connectToHost:@"127.0.0.1" onPort:torControllerPort withTimeout:(-5) error:&error];
                if (error)
                {
                    NSLog(@"Connection error: %@", error.userInfo);
                    error = NULL;
                }
               
                //Authenticate with that bitch
                [self.socket readDataWithTimeout:-1 tag:9150];
                [self.socket writeData:([authCommand dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]) withTimeout:-1 tag:9150];
            }
        }
    }
            
}
        



-(void)controllerDidAuthenticate
{
    self.controllerUp = YES;
    self.controllerStatus = @"Controller Authenticated.";
    NSLog(@"Controller Did Authenticate.");
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



- (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port 
{
    NSLog(@"%@ connected to %@ on port %d", sock, host, port);
    [sock startTLS:nil];    
}



- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err 
{
    NSLog(@"socket %@ disconnected, code %d: %@, %@", sock, err.code, err.userInfo, err.domain);
}



- (void) socketDidSecure:(GCDAsyncSocket *)sock 
{
    NSLog(@"socket secured: %@", sock);
    NSString *requestString = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nhost: %@\r\n\r\n", checkClientHost];
    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    [sock readDataWithTimeout:-1 tag:3567];
    [sock writeData:requestData withTimeout:-1 tag:3567];
}


        
    
- (void) socketDidCloseReadStream:(GCDAsyncSocket *)sock 
{
    NSLog(@"socket closed readstream: %@", sock);
}



- (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"did write data %@ with tag %ld", sock, tag);
    if (tag == 9150)
        {
            self.controllerStatus = [NSString stringWithFormat:@"Sent authentication to control port, awaiting response."];
            NSLog(@"sent authentication command to control port");
        }

    if (tag == 3567)
        {
            NSLog(@"wrote data to tests client functionality");
        }
}



- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag 
{

    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@ %ld did read data:\n%@\n", sock, tag, responseString);

                        
        if (tag == 9150)
            {
                if (!([responseString rangeOfString:AUTH_SUCCESS].location == NSNotFound))
                    {
                     
                        self.controllerStatus = @"Controller is UP and Authenticated";
                        self.controllerUp = YES;
                        NSLog(@"TOR Controller is up and Authenticated");
                        
                       
                    }
            }
    
    
        if (tag == 3567)
            {
                NSScanner *scanner = [NSScanner scannerWithString:responseString];
                NSCharacterSet *newLine = [NSCharacterSet newlineCharacterSet];
                NSCharacterSet *removeFirst = [NSCharacterSet characterSetWithCharactersInString:@"<p>Your IP address appears to be:  <strong>"];
                NSCharacterSet *removeSecond = [NSCharacterSet characterSetWithCharactersInString:@"</strong></"];
        
        
                NSString *currentLine = nil; 
                NSString *ipLine = nil; 
                NSString *trimIpLine = nil;
                NSString *returnedIP = nil;
        
        
        while (![scanner isAtEnd]) 
        {
            if([scanner scanUpToString:@"<p>Your IP address appears to be:  <strong>" intoString:&currentLine])
                {
                    ipLine = [currentLine stringByTrimmingCharactersInSet: newLine];   
                }
            if([scanner scanUpToCharactersFromSet:newLine intoString:&currentLine])
                {
                    trimIpLine = currentLine;
                    returnedIP = [trimIpLine stringByTrimmingCharactersInSet:removeFirst];
                    returnedIP = [returnedIP stringByTrimmingCharactersInSet:removeSecond];
                    NSLog(@"Check TOR returned your address as %@", returnedIP);
                
                
                //might want to check to make sure IP string is valid here
                
                    self.checkTorReturnedIP = returnedIP;
                
                    if (!(self.checkTorReturnedIP == nil))
                        {
                            self.clientStat = YES;
                        }
                
                    if (self.isClientUp)
                        {
                            [self authenticateController];
                        }
                }
        }
        
    }
    [sock readDataWithTimeout:-1 tag:3567];
}




@end