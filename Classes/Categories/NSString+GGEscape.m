//
//  NSString+Escape.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 29.12.10.
//  Copyright 2012 AppCode. All rights reserved.
//

#import "NSString+GGEscape.h"

@implementation NSString(GGEscape)

+ (NSString *)gg_stringByURLEncodingString:(NSString *)str {
	NSString *result = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return result;
}

// NSURL's stringByAddingPercentEscapesUsingEncoding: does not escape
// some characters that should be escaped in URL parameters, like / and ?;
// we'll use CFURL to force the encoding of those
//
// Reference: http://www.ietf.org/rfc/rfc3986.txt

const CFStringRef kCharsToForceEscape = CFSTR("!*'();:@&=+$,/?%#[]");

+ (NSString *)gg_stringByURLEncodingForURI:(NSString *)str {
	
	CFStringRef leaveUnescaped = NULL;
	
	CFStringRef escapedStr;
	escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
														 (__bridge CFStringRef)str,
														 leaveUnescaped,
														 kCharsToForceEscape,
														kCFStringEncodingUTF8);
	
	if (escapedStr) {
		return (NSString *)CFBridgingRelease(escapedStr);
	}
	
	return str;
}

@end
