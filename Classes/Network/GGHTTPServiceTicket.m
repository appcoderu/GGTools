//
//  GGHTTPServiceTicket.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPServiceTicket.h"
#import "GGHTTPServiceTicket+Private.h"

@implementation GGHTTPServiceTicket {
	NSObject <GGHTTPFetcherProtocol> *_fetcher;
}

@synthesize used=_used;
@synthesize query=_query;

- (NSObject <GGHTTPFetcherProtocol> *)fetcher {
	return _fetcher;
}

- (void)setFetcher:(NSObject<GGHTTPFetcherProtocol> *)fetcher {
	_fetcher = fetcher;
}

@end
