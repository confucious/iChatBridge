//
//  BonjourManager.h
//  iChatBridge
//
//  Created by John Garza on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <DNSServiceDiscovery/DNSServiceDiscovery.h>
#import <dns_sd.h>

@class AWEzvRendezvousData, ServiceController;

@interface BonjourManager : NSObject
{
	NSFileHandle	*listenSocket;
	NSMutableDictionary *contacts;
    
	//AWEzv		*client;
	int			isConnected;
    
	/* Listener related instance variables */
	unsigned int	port; /* port we're going to listen to*/
	
	/* Rendezvous related instance variables */
	AWEzvRendezvousData		*userAnnounceData;
    
	ServiceController		*fDomainBrowser;
	ServiceController		*fServiceBrowser;
	
	
	DNSServiceRef avDNSReference;
	DNSServiceRef imageServiceRef;
	DNSRecordRef imageRef;
    
	NSString *avInstanceName;
	NSData *imagehash;
    
	int				regCount;
    
}

- (void) login;
- (void) logout;
- (void) disconnect;
- (void) setConnected:(BOOL)connected;

- (void) updateAnnounceInfo;

- (NSString *)myInstanceName;

// REALLY PRIVATE STUFF
- (void) setInstanceName:(NSString *)newName;
- (void) regCallBack:(int)errorCode;

@end BonjourManager