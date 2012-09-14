//
//  GGHTTPCacheItem.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPCacheItem.h"
#import "GGCacheItem.h"

@implementation GGHTTPCacheItem {
	GGCacheItem *_cacheItem;
}

- (id)init {
	return [self initWithCacheItem:nil];
}

- (id)initWithCacheItem:(GGCacheItem *)cacheItem {
	self = [super init];
	if (self) {
		if (!cacheItem) {
			return nil;
		}
		_cacheItem = cacheItem;
	}
	return self;
}


- (GGCacheItem *)cacheItem {
	return _cacheItem;
}

#pragma mark -

- (NSDictionary *)responseHeaders {
	return [_cacheItem meta];
}

- (NSString *)lastModified {
	return [_cacheItem metaValueForKey:@"last-modified"];
}

- (NSString *)eTag {
	return [_cacheItem metaValueForKey:@"etag"];
}

- (NSData *)data {
	return [_cacheItem data];
}

- (NSTimeInterval)age {
	return [_cacheItem age];
}

- (NSTimeInterval)maxAge {
	NSString *cacheControl = [_cacheItem metaValueForKey:@"cache-control"];
	if (!cacheControl) {
		return 0.0;
	}
	
	NSTimeInterval maxAge = 0.0;
	
	NSScanner *scanner = [NSScanner scannerWithString:cacheControl];
	[scanner scanUpToString:@"max-age" intoString:NULL];
	if ([scanner scanString:@"max-age" intoString:NULL]) {
		[scanner scanString:@"=" intoString:NULL];
		[scanner scanDouble:&maxAge];
	}
	
	return maxAge;
}

#pragma mark -

- (BOOL)canBeUsedWithoutRevalidation {
	if ([self maxAge] - [self age] > 0.01) {
		return YES;
	}
	
	return NO;
}

@end
