//
//  torController.h
//  OnionKit
//
//  Created by Kenneth Gregory on 8/9/14.
//  Copyright (c) 2014 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


@interface torController : NSObject <GCDAsyncSocketDelegate>


@property (nonatomic, strong) NSString *controllerStatus;

//flags for statuses

@property (nonatomic, getter = isControllerUp) BOOL controllerUp;

@property (nonatomic, getter = isTorBootstrapped) BOOL *torStrapStat;

@property (nonatomic, getter = isClientUp) BOOL *clientStat;                    
//A TOR Controller

-(void)startTor;
-(void)startController;



@end
