//
//  GGHTTPServiceTicket.h
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGQuery;
@class GTMHTTPFetcher;
@class GGHTTPCacheItem;

@interface GGHTTPServiceTicket : NSObject

@property(nonatomic, retain) GGQuery *query;
@property(nonatomic, retain) GGHTTPCacheItem *cacheItem;
@property(nonatomic, assign, getter = isUsed) BOOL used;
@property(nonatomic, retain) GTMHTTPFetcher *fetcher;

@end
