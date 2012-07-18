//
//  GGHTTPCacheItem.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 05.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGCacheItem;

@interface GGHTTPCacheItem : NSObject

- (id)initWithCacheItem:(GGCacheItem *)item;

@property(nonatomic, readonly) NSString *lastModified;
@property(nonatomic, readonly) NSString *eTag;
@property(nonatomic, readonly) NSTimeInterval age;
@property(nonatomic, readonly) NSData *data;

- (BOOL)canBeUsedWithoutRevalidation;

@end
