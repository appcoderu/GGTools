//
//  GGHTTPServiceTicket.m
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPServiceTicket.h"

@implementation GGHTTPServiceTicket

@synthesize used=used_;
@synthesize query=query_;
@synthesize fetcher=fetcher_;
@synthesize cacheItem=cacheItem_;

- (void)dealloc {
	[cacheItem_ release];
    [query_ release];
	[fetcher_ release];
    [super dealloc];
}

@end
