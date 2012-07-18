//
//  GGHTTPCacheItem.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPCacheItem.h"
#import "GGCacheItem.h"

#warning return transformed data instead of plain data if possible

@implementation GGHTTPCacheItem {
	GGCacheItem *cacheItem;
}

- (id)init {
	return [self initWithCacheItem:nil];
}

- (id)initWithCacheItem:(GGCacheItem *)aCacheItem {
	self = [super init];
	if (self) {
		if (!aCacheItem) {
			return nil;
		}
		cacheItem = aCacheItem;
	}
	return self;
}


- (GGCacheItem *)cacheItem {
	return cacheItem;
}

#pragma mark -

- (NSString *)lastModified {
	return [cacheItem metaValueForKey:@"last-modified"];
}

- (NSString *)eTag {
	return [cacheItem metaValueForKey:@"etag"];
}

- (NSData *)data {
	return [cacheItem data];
}

- (NSTimeInterval)age {
	return [cacheItem age];
}

- (NSTimeInterval)maxAge {
	NSString *cacheControl = [cacheItem metaValueForKey:@"cache-control"];
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
