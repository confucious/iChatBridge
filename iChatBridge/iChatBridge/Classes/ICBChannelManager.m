//
//  ICBChannelManager.m
//  iChatBridge
//
//  Created by Jerry Hsu on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ICBChannelManager.h"

@implementation ICBChannelManager
@synthesize channelName = _channelName;
@synthesize contactId = _contactId;
@synthesize ezv = _ezv;
@synthesize ezvContact = _ezvContact;

- (id) init {
    self = [super init];
    if (self) {
        _ezv = [[AWEzv alloc] initWithClient: self];
    }
    return self;
}

- (void)dealloc
{
    [_channelName release];
    [_contactId release];
    [_ezv release];
    [_ezvContact release];
    [super dealloc];
}

- (void) connect {
    if ( ! (self.channelName && self.contactId)) {
        return;
    }
    [self.ezv setName: self.channelName];
    [self.ezv login];
}

- (void) disconnect {
    [self.ezv logout];
}

- (void) forwardRoomMessage:(NSString *)message {
    [self forwardRoomMessage: message andHtml: nil];
}

- (void) forwardRoomMessage:(NSString *)message andHtml:(NSString *)html {
    if (self.ezvContact) {
        if (html) {
            [self.ezvContact sendMessage: message withHtml: html];
        } else {
            [self.ezvContact sendMessage: message withHtml: message];
        }
    } else {
        // Queue the messages up. When the user connects, automatically send him everything.
    }
}

- (void) forwardUserMessage:(NSString *)message {
    [self forwardUserMessage: message andHtml: nil];
}

- (void) forwardUserMessage:(NSString *)message andHtml:(NSString *)html {
    // Default does nothing. Base class doesn't know anything.
}

#pragma mark - libezv delegate callbacks

- (void)reportLoggedIn {
    
}

- (void)reportLoggedOut {
    self.ezvContact = nil;
}

- (void)userLoggedOut:(AWEzvContact *)contact {
    if (contact == self.ezvContact) {
        self.ezvContact = nil;
    }
}

- (void)userChangedState:(AWEzvContact *)contact {
    if ([contact.uniqueID isEqualToString: self.contactId]) {
        NSLog(@"contact found %@: %@", [contact name], [contact uniqueID]);
        self.ezvContact = contact;
    }
}

- (void)userChangedImage:(AWEzvContact *)contact {
    
}

- (void)user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html {
    if (contact != self.ezvContact) {
        // Don't process message if it didn't come from the proper contact.
        return;
    }
    [self forwardUserMessage: message andHtml: html];
}

- (void) user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus {
    
}

- (void) user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html {
    
}

- (void)updateProgressForFileTransfer:(EKEzvFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent {
    
}

- (void)remoteCanceledFileTransfer:(EKEzvFileTransfer *)fileTransfer {
    
}

- (void)transferFailed:(EKEzvFileTransfer *)fileTransfer {
    
}

- (void)user:(AWEzvContact *)contact sentFile:(EKEzvFileTransfer *)fileTransfer {
    
}

- (void)remoteUserBeganDownload:(EKEzvOutgoingFileTransfer *)fileTransfer {
    
}

- (void)remoteUserFinishedDownload:(EKEzvOutgoingFileTransfer *)fileTransfer {
    
}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity {
    
}

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contact {
    
}


@end
