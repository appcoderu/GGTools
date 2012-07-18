//
//  NSDictionary+URL.m
//
//  Created by Evgeniy Shurakov on 04.06.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import "NSDictionary+URL.h"

#import "NSString+Escape.h"

@implementation NSDictionary (NSDictionary_URL)

- (NSString *)componentsAsParameterString {	
	NSMutableString *strParams = [NSMutableString stringWithString:@""];
	
	for (NSString *key in self) {
		id _value = [self objectForKey:key];
		id _key = [NSString stringByURLEncodingForURI:key];
		
		if (![_value isKindOfClass:[NSString class]]) {
			_value = [_value description];
		}
		
		_value = [NSString stringByURLEncodingForURI:_value];
		
		[strParams appendFormat:@"%@=%@&", _key, _value];
	}
	
	return strParams;
}

@end
