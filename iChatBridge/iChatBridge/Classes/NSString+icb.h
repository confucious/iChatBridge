//
//  NSString+icb.h
//  iChatBridge
//
//  Created by Jerry Hsu on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (icb)

+ (id) stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
+ (id)ellipsis;

- (NSString *)stringByAppendingEllipsis;
- (NSString *)stringWithEllipsisByTruncatingToLength:(NSUInteger)length;

@end
