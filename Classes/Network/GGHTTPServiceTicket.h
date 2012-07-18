//
//  GGHTTPServiceTicket.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGHTTPFetcherProtocol.h"

@class GGQuery;
@class GTMHTTPFetcher;
@class GGHTTPCacheItem;

@interface GGHTTPServiceTicket : NSObject

@property(nonatomic, strong) GGQuery *query;
@property(nonatomic, strong) GGHTTPCacheItem *cacheItem;
@property(nonatomic, assign, getter = isUsed) BOOL used;
@property(nonatomic, strong) NSObject <GGHTTPFetcherProtocol> *fetcher;

@end
