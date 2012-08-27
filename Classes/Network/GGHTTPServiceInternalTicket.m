//
//  GGHTTPServiceInternalTicket.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 8/27/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGHTTPServiceInternalTicket.h"

#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"
#import "GGHTTPServiceTicket+Private.h"

@implementation GGHTTPServiceInternalTicket {
	NSMutableArray *_clientTickets;
}

@synthesize query=_query;
@synthesize cachedItem=_cachedItem;
@synthesize clientTickets=_clientTickets;
@synthesize fetcher=_fetcher;
@synthesize used=_used;

+ (id)ticketWithQuery:(GGHTTPQuery *)query {
	return [[[self class] alloc] initWithQuery:query];
}

- (id)init {
	return [self initWithQuery:nil];
}

- (id)initWithQuery:(GGHTTPQuery *)query {
	self = [super init];
	if (self) {
		if (!query) {
			self = nil;
			return self;
		}
		
		_clientTickets = [[NSMutableArray alloc] initWithCapacity:3];
		_query = query;
	}
	
	return self;
}

- (void)addClientTicket:(GGHTTPServiceTicket *)ticket {
	ticket.internalTicket = self;
	[_clientTickets addObject:ticket];
}

- (void)removeClientTicket:(GGHTTPServiceTicket *)ticket {
	[_clientTickets removeObject:ticket];
}

- (void)removeAllClientTickets {
	[_clientTickets removeAllObjects];
}


@end
