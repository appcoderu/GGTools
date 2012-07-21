//
//  NSDictionary+URL.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 04.06.11.
//  Copyright 2012 AppCode. All rights reserved.
//

#import "NSDictionary+GGURL.h"

#import "NSString+GGEscape.h"

@implementation NSDictionary (NSDictionary_GGURL)

- (NSString *)gg_componentsAsParameterString {
	NSMutableString *strParams = [NSMutableString stringWithString:@""];
	
	for (NSString *key in self) {
		id _value = [self objectForKey:key];
		id _key = [NSString gg_stringByURLEncodingForURI:key];
		
		if (![_value isKindOfClass:[NSString class]]) {
			_value = [_value description];
		}
		
		_value = [NSString gg_stringByURLEncodingForURI:_value];
		
		[strParams appendFormat:@"%@=%@&", _key, _value];
	}
	
	return strParams;
}

@end
