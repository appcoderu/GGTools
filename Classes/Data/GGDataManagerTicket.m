//
//  GGDataManagerTicket.m
//
//  Created by Evgeniy Shurakov on 11.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGDataManagerTicket.h"

@implementation GGDataManagerTicket

@synthesize key, completionHandler;

+ (id)ticketWithKey:(NSString *)key completionHandler:(id)handler {
	return [[[self class] alloc] initWithKey:key completionHandler:handler];
}

- (id)initWithKey:(NSString *)aKey completionHandler:(id)aHandler {
	self = [super init];
	if (self) {
		if (!aKey || [aKey length] == 0) {
			self = nil;
			return self;
		}
		
		key = aKey;
		completionHandler = [aHandler copy];
	}
	
	return self;
}

@end
