//
//  NSString+Escape.m
//
//  Created by Evgeniy Shurakov on 29.12.10.
//  Copyright 2010 Evgeniy Shurakov. All rights reserved.
//

#import "NSString+Escape.h"

@implementation NSString(Escape)

+ (NSString *)stringByURLEncodingString:(NSString *)str {
	NSString *result = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return result;
}

// NSURL's stringByAddingPercentEscapesUsingEncoding: does not escape
// some characters that should be escaped in URL parameters, like / and ?;
// we'll use CFURL to force the encoding of those
//
// Reference: http://www.ietf.org/rfc/rfc3986.txt

const CFStringRef kCharsToForceEscape = CFSTR("!*'();:@&=+$,/?%#[]");

+ (NSString *)stringByURLEncodingForURI:(NSString *)str {
	
	NSString *resultStr = str;
	
	CFStringRef originalString = (CFStringRef) str;
	CFStringRef leaveUnescaped = NULL;
	
	CFStringRef escapedStr;
	escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
														 originalString,
														 leaveUnescaped,
														 kCharsToForceEscape,
														 kCFStringEncodingUTF8);
	if (escapedStr) {
		resultStr = [(id)CFMakeCollectable(escapedStr) autorelease];
	}
	return resultStr;
}

@end
