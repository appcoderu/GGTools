//
//  GGHTTPServiceTicket.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPServiceTicket.h"
#import "GGHTTPServiceTicket+Private.h"

#import "GGHTTPCacheItem.h"

@implementation GGHTTPServiceTicket {
	GGHTTPCacheItem *_cacheItem;
}

@synthesize used=_used;
@synthesize query=_query;
@synthesize fetcher=_fetcher;

- (GGHTTPCacheItem *)cacheItem {
	return _cacheItem;
}

- (void)setCacheItem:(GGHTTPCacheItem *)cacheItem {
	_cacheItem = cacheItem;
}

@end
