//
//  ICBChannelManager.h
//  iChatBridge
//
//  Created by Jerry Hsu on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWEzv.h"

// Base class to receive/find connection to an iChat contact.
// Subclass should handle connection to the MUC server as appropriate.

@interface ICBChannelManager : NSObject <AWEzvClientProtocol> {
    NSString* _channelName; // The channel name as presented over bonjour to user.
    NSString* _contactId; // Contact's unique Id.
    
    AWEzv* _ezv;
    AWEzvContact* _ezvContact;
}

@property (nonatomic, retain) NSString* channelName;
@property (nonatomic, retain) NSString* contactId;
@property (nonatomic, retain) AWEzv* ezv;
@property (nonatomic, retain) AWEzvContact* ezvContact;

- (void) connect;
- (void) disconnect;

- (void) forwardRoomMessage: (NSString*) message;
- (void) forwardRoomMessage: (NSString*) message andHtml: (NSString*) html;

// forwardUserMessage:andHtml: should be overridden by subclassses to send message
// to the room.
- (void) forwardUserMessage: (NSString*) message;
- (void) forwardUserMessage: (NSString *)message andHtml: (NSString*) html;

@end
