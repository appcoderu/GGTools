//
//  GGHTTPCacheItem.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGCacheItem;

@interface GGHTTPCacheItem : NSObject

- (id)initWithCacheItem:(GGCacheItem *)item;

@property(nonatomic, strong, readonly) NSString *lastModified;
@property(nonatomic, strong, readonly) NSString *eTag;
@property(nonatomic, readonly) NSTimeInterval age;
@property(nonatomic, strong, readonly) NSData *data;

- (BOOL)canBeUsedWithoutRevalidation;

@end
