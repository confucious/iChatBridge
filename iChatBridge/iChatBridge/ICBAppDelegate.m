//
//  ICBAppDelegate.m
//  iChatBridge
//
//  Created by Jerry Hsu on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ICBAppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@implementation ICBAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger: [DDTTYLogger sharedInstance]];
    
}

@end
