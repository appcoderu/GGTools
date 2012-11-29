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
	id _completionHandler;
	__weak GGHTTPServiceInternalTicket *_internalTicket;
}

@synthesize query=_query;
@synthesize used=_used;

- (id)completionHandler {
	return _completionHandler;
}

- (void)setCompletionHandler:(id)completionHandler {
	_completionHandler = [completionHandler copy];
}

- (GGHTTPServiceInternalTicket *)internalTicket {
	return _internalTicket;
}

- (void)setInternalTicket:(GGHTTPServiceInternalTicket *)internalTicket {
	_internalTicket = internalTicket;
}

@end
