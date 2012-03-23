//
//  ICBXmppChannelManager.h
//  iChatBridge
//
//  Created by Jerry Hsu on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ICBChannelManager.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPRoom.h"
#import "XMPPRoomMemoryStorage.h"

@interface ICBXmppChannelManager : ICBChannelManager <
XMPPStreamDelegate,
XMPPReconnectDelegate,
XMPPRoomDelegate> {
    XMPPStream* _stream;
    XMPPReconnect* _reconnect;
    XMPPRoom* _room;
    XMPPRoomMemoryStorage* _storage;
    
    NSString* _jabberAccount; // User jid
    NSString* _jabberHost;
    NSString* _jabberPassword;
    NSString* _roomName; // Room jid
    NSString* _userNickname;
}

@property (nonatomic, retain) XMPPStream* stream;
@property (nonatomic, retain) XMPPReconnect* reconnect;
@property (nonatomic, retain) XMPPRoom* room;
@property (nonatomic, retain) XMPPRoomMemoryStorage* storage;

@property (nonatomic, retain) NSString* jabberAccount;
@property (nonatomic, retain) NSString* jabberHost;
@property (nonatomic, retain) NSString* jabberPassword;
@property (nonatomic, retain) NSString* roomName;
@property (nonatomic, retain) NSString* userNickname;
@end
