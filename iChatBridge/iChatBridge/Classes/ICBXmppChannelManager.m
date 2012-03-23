//
//  ICBXmppChannelManager.m
//  iChatBridge
//
//  Created by Jerry Hsu on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ICBXmppChannelManager.h"

@implementation ICBXmppChannelManager
@synthesize stream = _stream;
@synthesize reconnect = _reconnect;
@synthesize room = _room;
@synthesize storage = _storage;
@synthesize jabberAccount = _jabberAccount;
@synthesize jabberHost = _jabberHost;
@synthesize jabberPassword = _jabberPassword;
@synthesize roomName = _roomName;
@synthesize userNickname = _userNickname;

- (id)init
{
    self = [super init];
    if (self) {
        _stream = [[XMPPStream alloc] init];
        [_stream addDelegate: self delegateQueue: dispatch_get_main_queue()];
        
        _reconnect = [[XMPPReconnect alloc] init];
        [_reconnect activate: _stream];

        _storage = [[XMPPRoomMemoryStorage alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_stream release];
    [_reconnect release];
    [_room release];
    [_storage release];
    
    [_jabberAccount release];
    [_jabberHost release];
    [_jabberPassword release];
    [_roomName release];
    [_userNickname release];
    [super dealloc];
}

- (void)connect {
    if ( ! (self.jabberAccount && self.roomName && self.userNickname)) {
        return;
    }

    [super connect];

    self.stream.myJID = [XMPPJID jidWithString: self.jabberAccount];
    if (self.jabberHost) {
        self.stream.hostName = self.jabberHost;
    }
    NSError* error = nil;
    [self.stream connect: &error];

    self.room = [[[XMPPRoom alloc] initWithRoomStorage: self.storage 
                                                 jid: [XMPPJID jidWithString: self.roomName]] autorelease];
    [self.room addDelegate: self delegateQueue: dispatch_get_main_queue()];
    [self.room activate: self.stream];

}

#pragma mark - Overridden methods

- (void)forwardUserMessage:(NSString *)message andHtml:(NSString *)html {
    [self.room sendMessage: message];
}

#pragma mark - XMPPRoomDelegate callbacks

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSError* error = nil;
    if ( self.jabberPassword ) {
        [self.stream authenticateWithPassword: self.jabberPassword error: &error];
    } else {
        [self.stream authenticateAnonymously: &error];
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    [self.room joinRoomUsingNickname: self.userNickname
                             history: [NSXMLElement elementWithName: @"history"
                                                           children: nil
                                                         attributes: [NSArray arrayWithObject: [NSXMLNode attributeWithName: @"maxstanzas"
                                                                                                                stringValue: @"10"]]
                                       ]];
}

- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID {
    if ([[occupantJID resource] isEqualToString: self.userNickname] && ! [message elementForName: @"delay"]) {
        // Message is from ourself and isn't history. So ignore it.
        return;
    }
    NSString* time = [[message elementForName: @"delay"] attributeStringValueForName: @"stamp"];
    NSString* send = [NSString stringWithFormat: @"%@ %@ - %@",
                      time,
                      [occupantJID resource],
                      [[message elementForName: @"body"] stringValue] ];
    [self forwardRoomMessage: send];
}


@end
