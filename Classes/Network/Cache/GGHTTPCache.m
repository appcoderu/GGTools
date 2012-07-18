//
//  GGHTTPCache.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 04.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPCache.h"
#import "GGHTTPCacheItem.h"
#import "GGCache.h"

#import "NSString+Crypto.h"

@interface GGHTTPCacheItem (Private)
- (GGCacheItem *)cacheItem;
@end

@implementation GGHTTPCache {
	GGCache *cache;
}

+ (id)sharedCache {
	static GGHTTPCache *sharedInstance = nil;
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		sharedInstance = [[[self class] alloc] initWithCoreCache:[GGCache sharedCache]];
	});
	
	return sharedInstance;
}

- (id)initWithCoreCache:(GGCache *)aCache {
	self = [super init];
	if (self) {
		if (!aCache) {
			return nil;
		}
		cache = aCache;
	}
	
	return self;
}


- (BOOL)canCacheRequest:(NSURLRequest *)request {
	if (!request) {
		return NO;
	}
	
	if (request.HTTPMethod && [request.HTTPMethod localizedCaseInsensitiveCompare:@"GET"] != NSOrderedSame) {
		return NO;
	}
	
	return YES;
}

- (NSString *)cacheKeyForRequest:(NSURLRequest *)request {
	return [[request.URL absoluteString] sha1];
}

- (GGHTTPCacheItem *)cachedItemForRequest:(NSURLRequest *)request {
	if (![self canCacheRequest:request]) {
		return nil;
	}
	
	GGCacheItem *item = [cache cachedItemForKey:[self cacheKeyForRequest:request]];
	return [[GGHTTPCacheItem alloc] initWithCacheItem:item];
}

- (void)storeData:(NSData *)data forRequest:(NSURLRequest *)request response:(NSURLResponse *)response {
	if (![self canCacheRequest:request]) {
		return;
	}
	
	NSDictionary *d1 = [(NSHTTPURLResponse *)response allHeaderFields];
	NSMutableDictionary *d2 = nil;
	
	if (d1 && [d1 count] > 0) {
		d2 = [NSMutableDictionary dictionaryWithCapacity:[d1 count]];
		[d1 enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[d2 setObject:obj forKey:[key lowercaseString]];
		}];
	}
	
	if (![d2 objectForKey:@"last-modified"] && ![d2 objectForKey:@"etag"]) {
		return;
	}
	
	[cache storeData:data 
			withMeta:d2 
			  forKey:[self cacheKeyForRequest:request]];
}

- (void)bumpAgeOfCachedItem:(GGHTTPCacheItem *)cacheItem {
	[cache bumpAgeOfCachedItem:[cacheItem cacheItem]];
}

- (void)clear {
	[cache clear];
}

@end
