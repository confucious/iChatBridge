#import "AWEzvRendezvousData.h"
#import "BonjourManager.h"

#import <dns_sd.h>
#import <openssl/sha.h>

#define BIND_8_COMPAT 1

#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/nameser.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <resolv.h>
#import <errno.h>
#import <ctype.h>
#import <string.h>
#import <stdlib.h>

#import <SystemConfiguration/SystemConfiguration.h>

// The ServiceController manages cleanup of DNSServiceRef & runloop info for an outstanding request
@interface ServiceController : NSObject
{
	DNSServiceRef			fServiceRef;
	CFSocketRef				fSocketRef;
	CFRunLoopSourceRef		fRunloopSrc;
    BonjourManager          *bonjourManager;
}

- (id)initWithServiceRef:(DNSServiceRef)ref forBonjourManager: (BonjourManager *)inBonjourManager;
- (boolean_t)addToCurrentRunLoop;
- (void)breakdownServiceController;
- (DNSServiceRef)serviceRef;

@property (readonly, nonatomic) BonjourManager *bonjourManager;

@end // Interface ServiceController

// C-helper function prototypes
void register_reply ( 
                     DNSServiceRef sdRef, 
                     DNSServiceFlags flags, 
                     DNSServiceErrorType errorCode, 
                     const char *name, 
                     const char *regtype, 
                     const char *domain, 
                     void *context
                     );

static void ProcessSockData (
                             CFSocketRef s,
                             CFSocketCallBackType callbackType,
                             CFDataRef address,
                             const void *data,
                             void *info
                             );

void handle_av_browse_reply ( 
                             DNSServiceRef sdRef, 
                             DNSServiceFlags flags, 
                             uint32_t interfaceIndex, 
                             DNSServiceErrorType errorCode, 
                             const char *serviceName, 
                             const char *regtype, 
                             const char *replyDomain, 
                             void *context
                             );

void resolve_reply ( 
                    DNSServiceRef sdRef, 
                    DNSServiceFlags flags, 
                    uint32_t interfaceIndex, 
                    DNSServiceErrorType errorCode, 
                    const char *fullname, 
                    const char *hosttarget, 
                    uint16_t port, 
                    uint16_t txtLen, 
                    const unsigned char *txtRecord, 
                    void *context
                    );

void AddressQueryRecordReply(DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
                             DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
                             uint16_t rdlen, const void *rdata, uint32_t ttl, void *context );

void ImageQueryRecordReply(DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
                           DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
                           uint16_t rdlen, const void *rdata, uint32_t ttl, void *context );	

void image_register_reply ( 
                           DNSServiceRef sdRef, 
                           DNSRecordRef RecordRef, 
                           DNSServiceFlags flags, 
                           DNSServiceErrorType errorCode, 
                           void *context
                           );							

@implementation BonjourManager

#pragma mark Announcing Functions

- (void) login
{
	regCount = 0;
    
	// Create data structure we'll advertise with (dummy data)
	userAnnounceData = [[AWEzvRendezvousData alloc] init];
	// Set field contents of the data
	[userAnnounceData setField:@"1st" content:@""];
    //[client name]];
	[userAnnounceData setField:@"email" content:@"garza@cjas.org"];
	[userAnnounceData setField:@"ext" content:@""];
	[userAnnounceData setField:@"jid" content:@""];
	[userAnnounceData setField:@"last" content:@"garza"];
	[userAnnounceData setField:@"msg" content:@"learning obj-c"];
	[userAnnounceData setField:@"nick" content:@"garza@cjas.org"];
	[userAnnounceData setField:@"node" content:@""];
	[userAnnounceData setField:@"AIM" content:@""];
	[userAnnounceData setField:@"email" content:@""];
	[userAnnounceData setField:@"port.p2pj" content:[NSString stringWithFormat:@"%u", port]];
	[userAnnounceData setField:@"txtvers" content:@"1"];
	[userAnnounceData setField:@"version" content:@"1"];
    
	//[self setStatus:[client status] withMessage:nil];
	
    // Register service with mDNSResponder
    
	DNSServiceRef servRef;
	DNSServiceErrorType dnsError;
    
	TXTRecordRef txtRecord;
	txtRecord = [userAnnounceData dataAsTXTRecordRef];
    
	dnsError = DNSServiceRegister(
                                  /* Uninitialized service discovery reference */ &servRef, 
                                  /* Flags indicating how to handle name conflicts */ /* kDNSServiceFlagsNoAutoRename */ 0, 
                                  /* Interface on which to register, 0 for all available */ kDNSServiceInterfaceIndexLocalOnly, 
                                  /* Service's name, may be null */ [avInstanceName UTF8String],
                                  /* Service registration type */ "_presence._tcp", 
                                  /* Domain, may be NULL */ NULL,
                                  /* SRV target host name, may be NULL */ NULL,
                                  /* Port number in network byte order */ htons(port), 
                                  /* Length of txt record in bytes, 0 for NULL txt record */ TXTRecordGetLength(&txtRecord) , 
                                  /* Txt record properly formatted, may be NULL */ TXTRecordGetBytesPtr(&txtRecord) ,
                                  /* Call back function, may be NULL */ register_reply,
                                  /* Application context pointer, may be null */ self
                                  );
    
	if (dnsError == kDNSServiceErr_NoError) {		
		fDomainBrowser = [[ServiceController alloc] initWithServiceRef:servRef forBonjourManager:self];
		[fDomainBrowser addToCurrentRunLoop];
		avDNSReference = servRef;
	} else {
        NSLog(@"Could not register DNS service: _presence._tcp");
		[self disconnect];
	}
    
	TXTRecordDeallocate(&txtRecord);
}

// This is used for a clean logout
- (void) logout
{
    [self disconnect];
}

// This causes an actual disconnect
- (void) disconnect
{
    NSLog(@"BonjourManager is disconnecting...");
    
	[fServiceBrowser release]; fServiceBrowser = nil;
    
	// Remove Resolvers, this also deallocates the DNSServiceReferences
	if (fDomainBrowser != nil) {
        NSLog(@"Releasing %@", fDomainBrowser);
		[fDomainBrowser release]; fDomainBrowser = nil;
		avDNSReference = nil;
		imageServiceRef = nil;
	}
	[self setConnected:NO];
}

- (void) setConnected:(BOOL)connected
{
	if (isConnected != connected) {
		isConnected = connected;
        
		if (connected) {
            NSLog(@"bonjour connected state: logged in");
		} else {
            NSLog(@"bonjour connected state: logged out");
		}
	}
}

// Udpates information announced over network for user
- (void) updateAnnounceInfo
{
	DNSServiceErrorType updateError;
	TXTRecordRef txtRecord;
    
	if (!isConnected) {
		return;
	}
    
	if (avDNSReference == NULL) {
        NSLog(@"avDNSReference is null when trying to update the TXT record");
		return;
	}
    
	txtRecord = [userAnnounceData dataAsTXTRecordRef];
    NSLog(@"%@", [userAnnounceData dictionary]);
	updateError = DNSServiceUpdateRecord (
                                          /* serviceRef */ avDNSReference,
                                          /* recordRef, may be NULL */ NULL,
                                          /* Flags, currently ignored */ 0,
                                          /* length */ TXTRecordGetLength(&txtRecord),
                                          /* data */ TXTRecordGetBytesPtr(&txtRecord),
                                          /* time to live */ 0
                                          );
    
	if (updateError != kDNSServiceErr_NoError) {		
        NSLog(@"Error updating TXT Record");
		[self disconnect];
	}
	
	TXTRecordDeallocate(&txtRecord);
}

#pragma mark Browsing Functions
- (NSString *)myInstanceName
{
	return avInstanceName;
}

- (void)setInstanceName:(NSString *)newName
{
	if (avInstanceName != newName) {
		[avInstanceName release];
		avInstanceName = [newName retain];
	}
}

- (void) regCallBack:(int)errorCode
{
	// Recover if there was an error
    if (errorCode != kDNSServiceErr_NoError) {
		switch (errorCode) {
#warning Localize and report through the connection error system
			case kDNSServiceErr_Unknown:
                NSLog(@"Unknown error in Bonjour Registration");
				break;
			case kDNSServiceErr_NameConflict:
                NSLog(@"A user with your Bonjour data is already online");
				break;
			default:
                NSLog(@"An internal error occurred");
				break;
		}
		// Kill connections
		[self disconnect];
	} else {
		[self setConnected:YES];
		//[self startBrowsing];
	}
}
@end

#pragma mark mDNS Callbacks
#pragma mark mDNS Register Callbacks

void register_reply(DNSServiceRef sdRef, DNSServiceFlags flags, DNSServiceErrorType errorCode, const char *name, const char *regtype, const char *domain, void *context)
{
    BonjourManager *self = context;
	//AWEzvContactManager *self = context;
	[self setInstanceName:[NSString stringWithUTF8String:name]];
	[self regCallBack:errorCode];
}

#pragma mark mDNS Browse Callback

/*!
 * @brief DNSServiceBrowse callback
 *
 * This may be called multiple times for a single use of DNSServiceBrowse().
 */
void handle_av_browse_reply(DNSServiceRef sdRef,
							DNSServiceFlags flags,
							uint32_t interfaceIndex,
							DNSServiceErrorType errorCode,
							const char *serviceName,
							const char *regtype,
							const char *replyDomain,
							void *context)
{
	// Received a browser reply from DNSServiceBrowse for av, now must handle processing the list of results
	if (errorCode == kDNSServiceErr_NoError) {
        BonjourManager *self = context;
	    if (![[self myInstanceName] isEqualToString:[NSString stringWithUTF8String:serviceName]]) {
			//[self browseResultwithFlags:flags onInterface:interfaceIndex name:serviceName type:regtype domain:replyDomain av:YES];
		}
	} else {
		//AWEzvLog(@"Error browsing");
        NSLog(@"Error browsing");
	}
}

#pragma mark mDNS Resolve Callback

/*!
 * @brief DNSServiceResolve callback
 *
 * This may be called multiple times for a single use of DNSServiceResolve().
 */
void resolve_reply( DNSServiceRef sdRef, 
                   DNSServiceFlags flags, 
                   uint32_t interfaceIndex, 
                   DNSServiceErrorType errorCode, 
                   const char *fullname, 
                   const char *hosttarget, 
                   uint16_t port, 
                   uint16_t txtLen, 
                   const unsigned char *txtRecord, 
                   void *context)
{
	if (errorCode == kDNSServiceErr_NoError) {
		// Use TXTRecord methods to resolve this
        //BonjourManager  *contact = context;
		//AWEzvContact	*contact = context;
		//AWEzvContactManager *self = [contact manager];
		
        // AWEzvLog(@"Would update contact");
		AWEzvRendezvousData *data;
		data = [[[AWEzvRendezvousData alloc] initWithTXTRecordRef:txtRecord length:txtLen] autorelease];
		//[self findAddressForContact:contact withHost:[NSString stringWithUTF8String:hosttarget] withInterface:interfaceIndex];
		//[self updateContact:contact withData:data withHost:[NSString stringWithUTF8String:hosttarget] withInterface:interfaceIndex withPort:ntohs(port) av:YES];
	} else {
        NSLog(@"Error resolving records");
	}	
}

#pragma mark Service Controller

// ServiceController was taken from Apple's DNSServiceBrowser.m
@implementation ServiceController : NSObject

#pragma mark CFSocket Callback

// This code was taken from Apple's DNSServiceBrowser.m
static void	ProcessSockData( CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// CFRunloop callback that notifies dns_sd when new data appears on a DNSServiceRef's socket.
{
	ServiceController *self = (ServiceController *)info;
    NSLog(@"Processing result for %@", self);
    
	DNSServiceErrorType err = DNSServiceProcessResult([self serviceRef]);
	
	if (err != kDNSServiceErr_NoError) {
		if ((err == kDNSServiceErr_Unknown) && !data) {
			// Try to accept(2) a connection. May be the cause of a hang on Tiger; see #7887.
			int socketFD = CFSocketGetNative(s);
			int childFD = accept(socketFD, /*addr*/ NULL, /*addrlen*/ NULL);
            NSLog(@"%@: Service ref %p received an unknown error with no data; perhaps mDNSResponder crashed? Result of calling accept(2) on fd %d is %d; will disconnect with error",
                  self, [self serviceRef], socketFD, childFD);
			// We don't actually *want* a connection, so close the socket immediately.
			if (childFD > -1) {
				close(childFD);
			}
            
			[self retain];
            
			//[[self contactManager] serviceControllerReceivedFatalError:self];
			[self breakdownServiceController];
			[self release];
            
		} else {
            NSLog(@"DNSServiceProcessResult() for socket descriptor %d returned an error! %d with CFSocketCallBackType",
            //      %d and data %s\n",
                  DNSServiceRefSockFD(info), err);
            //, type, data);
                  
			//AILog(@"DNSServiceProcessResult() for socket descriptor %d returned an error! %d with CFSocketCallBackType %d and data %s\n",
              //    DNSServiceRefSockFD(info), err, type, data);
		}
	}
}

- (id) initWithServiceRef:(DNSServiceRef) ref forBonjourManager:(BonjourManager *)inBonjourManager
{
	if ((self = [super init])) {
		fServiceRef = ref;
        bonjourManager = [inBonjourManager retain];
	}
    
	return self;
}

- (boolean_t) addToCurrentRunLoop
// Add the service to the current runloop. Returns non-zero on success.
{
	CFSocketContext	ctx = { 1, self, NULL, NULL, NULL };
    
	fSocketRef = CFSocketCreateWithNative(kCFAllocatorDefault, DNSServiceRefSockFD(fServiceRef),
                                          kCFSocketReadCallBack, ProcessSockData, &ctx);
	if (fSocketRef != NULL) {
		fRunloopSrc = CFSocketCreateRunLoopSource(kCFAllocatorDefault, fSocketRef, 1);
	}
	
	if (fRunloopSrc != NULL) {
		NSLog(@"Adding run loop source %p from run loop %p", fRunloopSrc, CFRunLoopGetCurrent());
		CFRunLoopAddSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
	} else {
        NSLog(@"%@: Could not listen to runloop socket", self);
	}
    
	return (fRunloopSrc != NULL);
}

- (DNSServiceRef) serviceRef
{
	return fServiceRef;
}

- (BonjourManager *)bonjourManager
{
    return bonjourManager;
}

- (void) dealloc
// Remove service from runloop, deallocate service and associated resources
{
    NSLog(@"%@", self);
	[self breakdownServiceController];
	[super dealloc];
}

- (void)breakdownServiceController
{
	NSLog(@"%@", self);
    
	if (fSocketRef != NULL) {
		CFSocketInvalidate(fSocketRef);	// Note: Also closes the underlying socket
		CFRelease(fSocketRef);
		fSocketRef = NULL;
	}
    
	if (fRunloopSrc != NULL) {
		NSLog(@"Removing run loop source %p from run loop %p", fRunloopSrc, CFRunLoopGetCurrent());
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
		CFRelease(fRunloopSrc);
		fRunloopSrc = NULL;
	}
    
	if (fServiceRef) {
		NSLog(@"Deallocating DNSServiceRef %p", fServiceRef);
		DNSServiceRefDeallocate(fServiceRef);
		fServiceRef = NULL;
	}
    
    [bonjourManager release]; bonjourManager = nil;
}
@end // Implementation ServiceController
