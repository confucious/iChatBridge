//
//  ICBAppDelegate.h
//  iChatBridge
//
//  Created by Jerry Hsu on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "XMPP.h"
#import "XMPPRoom.h"

@interface ICBAppDelegate : NSObject <NSApplicationDelegate,
XMPPStreamDelegate,
XMPPRoomDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
