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

#import "NSString+GGCrypto.h"

@interface GGHTTPCacheItem (Private)
- (GGCacheItem *)cacheItem;
@end

@implementation GGHTTPCache {
	GGCache *_coreCache;
}

+ (id)sharedCache {
	static GGHTTPCache *sharedInstance = nil;
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		sharedInstance = [[[self class] alloc] initWithCoreCache:[GGCache sharedCache]];
	});
	
	return sharedInstance;
}

- (id)initWithCoreCache:(GGCache *)cache {
	self = [super init];
	if (self) {
		if (!cache) {
			return nil;
		}
		_coreCache = cache;
	}
	
	return self;
}

- (NSString *)cacheKeyForURL:(NSURL *)url {
	return [[url absoluteString] gg_sha1];
}

- (GGHTTPCacheItem *)cachedItemForURL:(NSURL *)url {
	return [[GGHTTPCacheItem alloc] initWithCacheItem:[_coreCache cachedItemForKey:[self cacheKeyForURL:url]]];
}

- (void)storeData:(NSData *)data
		  headers:(NSDictionary *)rawHeaderFields
		   forURL:(NSURL *)url {
	if (!url) {
		return;
	}

	NSMutableDictionary *headerFields = nil;
	
	if (rawHeaderFields && [rawHeaderFields count] > 0) {
		headerFields = [NSMutableDictionary dictionaryWithCapacity:[rawHeaderFields count]];
		[rawHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[headerFields setObject:obj forKey:[key lowercaseString]];
		}];
	}
	
	if (![headerFields objectForKey:@"last-modified"] &&
		![headerFields objectForKey:@"etag"] &&
		![headerFields objectForKey:@"cache-control"]) {
		return;
	}
		
	[_coreCache storeData:data 
			withMeta:headerFields
			  forKey:[self cacheKeyForURL:url]];
}

- (void)bumpAgeOfCachedItem:(GGHTTPCacheItem *)cacheItem {
	[_coreCache bumpAgeOfCachedItem:[cacheItem cacheItem]];
}

- (void)clear {
	[_coreCache clear];
}

@end
