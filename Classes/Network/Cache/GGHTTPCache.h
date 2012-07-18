//
//  GGHTTPCache.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 04.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGHTTPCacheProtocol.h"

@class GGCache;

@interface GGHTTPCache : NSObject <GGHTTPCacheProtocol>

+ (id)sharedCache;

- (id)initWithCoreCache:(GGCache *)cache;

@end
