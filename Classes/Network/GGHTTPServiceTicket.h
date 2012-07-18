//
//  GGHTTPServiceTicket.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGHTTPFetcherProtocol;

@class GGHTTPQuery;
@class GTMHTTPFetcher;
@class GGHTTPCacheItem;

@interface GGHTTPServiceTicket : NSObject

@property(nonatomic, strong) GGHTTPQuery *query;
@property(nonatomic, strong) GGHTTPCacheItem *cacheItem;
@property(nonatomic, assign, getter = isUsed) BOOL used;
@property(nonatomic, strong) NSObject <GGHTTPFetcherProtocol> *fetcher;

@end
