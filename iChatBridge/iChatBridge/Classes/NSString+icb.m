//
//  NSString+icb.m
//  iChatBridge
//
//  Created by Jerry Hsu on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+icb.h"

@implementation NSString (icb)

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}

+ (id)ellipsis
{
	return [self stringWithUTF8String:"\xE2\x80\xA6"];
}

- (NSString *)stringByAppendingEllipsis
{
	return [self stringByAppendingString:[NSString stringWithUTF8String:"\xE2\x80\xA6"]];
}

- (NSString *)stringWithEllipsisByTruncatingToLength:(NSUInteger)length
{
	NSString *returnString;
	
	if (length < [self length]) {
		//Truncate and append the ellipsis
		returnString = [[self substringToIndex:length-1] stringByAppendingString:[NSString ellipsis]];
	} else {
		//We don't need to truncate, so don't append an ellipsis
		returnString = [[self copy] autorelease];
	}
	
	return (returnString);
}
@end
