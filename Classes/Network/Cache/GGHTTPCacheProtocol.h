//
//  GGHTTPCacheProtocol.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 04.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPCacheItem;

@protocol GGHTTPCacheProtocol <NSObject>

- (GGHTTPCacheItem *)cachedItemForURL:(NSURL *)url;

- (void)storeData:(NSData *)data
		  headers:(NSDictionary *)headers 
		   forURL:(NSURL *)url;

- (void)bumpAgeOfCachedItem:(GGHTTPCacheItem *)cacheItem;

- (void)clear;

@end
