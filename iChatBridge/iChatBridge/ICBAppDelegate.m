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
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPRoom.h"
#import "XMPPRoomMessage.h"
#import "XMPPRoomMemoryStorage.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@implementation ICBAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

static AWEzv* ezv;
static XMPPStream* stream;
static XMPPReconnect* xmppReconnect;
static XMPPRoom* xmppRoom;
static XMPPRoomMemoryStorage* storage;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [DDLog addLogger: [DDTTYLogger sharedInstance]];
    ezv = [[AWEzv alloc] initWithClient: self];
    [ezv setName: @"testClient"];
    [ezv login];
    stream = [[XMPPStream alloc] init];
    stream.myJID = [XMPPJID jidWithString: @"randomjid@jabber.org"];
    stream.hostName = @"somewhere.org";
    [stream addDelegate: self delegateQueue: dispatch_get_main_queue()];
    xmppReconnect = [[XMPPReconnect alloc] init];
    [xmppReconnect activate: stream];
    NSError* error = nil;
    [stream connect: &error];
    
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSError* error = nil;
    [stream authenticateAnonymously: &error];
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    storage = [[XMPPRoomMemoryStorage alloc] init];
    xmppRoom = [[XMPPRoom alloc] initWithRoomStorage: storage 
                                                 jid: [XMPPJID jidWithString: @"somewhere@chat.somewhere.org"]];
    [xmppRoom addDelegate: self delegateQueue: dispatch_get_main_queue()];
    [xmppRoom activate: stream];
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

static AWEzvContact* lastSeenContact = nil;

- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html {
    NSLog(@"received %@: %@ - %@\nhtml:%@", [contact name], [contact uniqueID], message, html);
    if (! lastSeenContact) {
        lastSeenContact = [contact retain];
        [xmppRoom joinRoomUsingNickname: @"JerryHsu"
                                history: [NSXMLElement elementWithName: @"history"
                                                              children: nil
                                                            attributes: [NSArray arrayWithObject: [NSXMLNode attributeWithName: @"maxstanzas"
                                                                                                                   stringValue: @"10"]]
                                          ]];
    }
    [xmppRoom sendMessage: message];
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID {
    NSString* send = [NSString stringWithFormat: @"%@ %@ - %@",
                         [[message elementForName: @"stamp"] stringValue],
                         [occupantJID resource],
                         [[message elementForName: @"body"] stringValue] ];
    [lastSeenContact sendMessage: send withHtml: send];
}

- (void)user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus {
    
}

- (void)user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
    
}

@end
