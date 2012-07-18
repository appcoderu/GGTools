//
//  GGCache.h
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGCacheItem;

@interface GGCache : NSObject

+ (GGCache *)sharedCache;
+ (void)setSharedCache:(GGCache *)cache;

- (id)initWithFolder:(NSString *)folder countLimit:(NSUInteger)countLimit;
- (id)initWithPath:(NSString *)path countLimit:(NSUInteger)countLimit;

- (GGCacheItem *)cachedItemForKey:(NSString *)key;

- (GGCacheItem *)storeData:(NSData *)data 
				  withMeta:(NSDictionary *)meta 
					forKey:(NSString *)key;

- (void)bumpAgeOfCachedItem:(GGCacheItem *)cacheItem;

- (BOOL)save;
- (void)clear;

- (NSUInteger)countLimit;
- (void)setCountLimit:(NSUInteger)countLimit;

- (NSString *)path;

@end
