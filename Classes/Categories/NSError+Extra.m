//
//  NSError+Extra.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 04.08.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import "NSError+Extra.h"

@implementation NSError (NSError_Extra)

+ (id)errorWithDomain:(NSString *)domain 
				 code:(NSInteger)code 
		  description:(NSString *)description 
		failureReason:(NSString *)failureReason {
	return [self errorWithDomain:domain 
							code:code 
					 description:description 
				   failureReason:failureReason 
				 underlyingError:nil];
}

+ (id)errorWithDomain:(NSString *)domain 
				 code:(NSInteger)code 
		  description:(NSString *)description 
		failureReason:(NSString *)failureReason 
	  underlyingError:(NSError *)error {
	
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
	if (description) {
		[userInfo setObject:description forKey:NSLocalizedDescriptionKey];
	}
	
	if (failureReason) {
		[userInfo setObject:failureReason forKey:NSLocalizedFailureReasonErrorKey];
	}
	
	if (error) {
		[userInfo setObject:error forKey:NSUnderlyingErrorKey];
	}
	
	return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

@end
