//
//  GGHTTPServiceTicket+Private.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPCacheItem;

@interface GGHTTPServiceTicket (Private)

@property(nonatomic, strong) GGHTTPCacheItem *cacheItem;

@end