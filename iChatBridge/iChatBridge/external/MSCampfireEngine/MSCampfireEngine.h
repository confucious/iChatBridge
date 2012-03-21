//
//  MSTCampfireEngine.h
//  AdiumCampfire
//
//  Created by Marek Stępniowski on 10-03-11.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSHTTPConnection.h"
#import "JSON.h"


@interface NSObject (MSCampfireEngineDelegate)

- (void)didReceiveRooms:(NSDictionary *)rooms;
- (void)didReceiveRoomInformation:(NSDictionary *)room;
- (void)didReceiveInformationForUser:(NSDictionary *)user;
- (void)didReceiveMessage:(NSDictionary *)message;
- (void)didReceiveInformationForAuthenticatedUser:(NSDictionary *)user;
- (void)didReceiveUpload:(NSDictionary *)upload;
@end


@interface MSCampfireEngine : NSObject <MSHTTPConnectionDelegate> {
  NSObject *delegate;
  NSString *_APIDomain;
  NSString *_key;
  BOOL _secureConnection;
  NSMutableDictionary *connections;
}

- (MSCampfireEngine *)initWithDomain: (NSString *)domain key:(NSString *)key delegate:(NSObject *)newDelegate;

- (void)getRooms;
- (void)getRoomInformationFor:(NSInteger)roomId;
- (void)getInformationForUser:(NSInteger)userId;
- (void)getInformationForAuthenticatedUser;
- (void)joinRoom:(NSInteger)roomId;
- (void)leaveRoom:(NSInteger)roomId;
- (void)sendTextMessage:(NSString *)message toRoom:(NSInteger)roomId;
- (void)getUploadForId:(NSInteger)uploadId inRoom:(NSInteger)roomId;

// Streaming API
- (void)startListeningForMessagesInRoom:(NSInteger)roomId;
- (void)stopListeningForMessagesInRoom:(NSInteger)roomId;

@end
