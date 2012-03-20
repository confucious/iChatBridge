//
//  ICBAppDelegate.m
//  iChatBridge
//
//  Created by Jerry Hsu on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ICBAppDelegate.h"
#import "AWEzvContactManagerRendezvous.h"

@implementation ICBAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

static AWEzv* ezv;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ezv = [[AWEzv alloc] initWithClient: self];
    [ezv setName: @"testClient"];
    [ezv login];
    
}

- (void)reportLoggedIn {
    
}

- (void)reportLoggedOut {
    
}

- (void)userLoggedOut:(AWEzvContact *)contact {

}

- (void)userChangedState:(AWEzvContact *)contact {
    NSLog(@"contact found %@: %@", [contact name], [contact uniqueID]);
}

- (void)userChangedImage:(AWEzvContact *)contact {
    
}

- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html {
    NSLog(@"received %@: %@ - %@", [contact name], [contact uniqueID], message);
    [contact sendMessage: message withHtml: html];
}

- (void)user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus {
    
}

- (void)user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
    
}

@end
