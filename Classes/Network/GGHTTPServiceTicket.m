//
//  GGHTTPServiceTicket.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPServiceTicket.h"
#import "GGHTTPServiceTicket+Private.h"

#import "GGHTTPService.h"

@implementation GGHTTPServiceTicket {
	GGHTTPServiceCompletionHandler _completionHandler;
	__weak GGHTTPServiceInternalTicket *_internalTicket;
}

@synthesize query=_query;
@synthesize used=_used;

- (GGHTTPServiceCompletionHandler)completionHandler {
	return _completionHandler;
}

- (void)setCompletionHandler:(GGHTTPServiceCompletionHandler)completionHandler {
	_completionHandler = [completionHandler copy];
}

- (GGHTTPServiceInternalTicket *)internalTicket {
	return _internalTicket;
}

- (void)setInternalTicket:(GGHTTPServiceInternalTicket *)internalTicket {
	_internalTicket = internalTicket;
}

@end
