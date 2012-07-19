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

- (GGHTTPCacheItem *)cachedItemForRequest:(NSURLRequest *)request;
- (void)storeData:(NSData *)data forRequest:(NSURLRequest *)request response:(NSHTTPURLResponse *)response;
- (void)bumpAgeOfCachedItem:(GGHTTPCacheItem *)cacheItem;

- (void)clear;

@end
