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

- (id)initWithFolder:(NSString *)folder;
- (id)initWithPath:(NSString *)path;

- (GGCacheItem *)cachedItemForKey:(NSString *)key;

- (GGCacheItem *)storeData:(NSData *)data 
				  withMeta:(NSDictionary *)meta 
					forKey:(NSString *)key;

- (BOOL)save:(NSError **)error;
- (void)clear;

- (NSUInteger)countLimit;
- (void)setCountLimit:(NSUInteger)countLimit;

@end
