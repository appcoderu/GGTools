//
//  NSError+Extra.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 04.08.11.
//  Copyright 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (NSError_GGExtra)

+ (id)gg_errorWithDomain:(NSString *)domain
				 code:(NSInteger)code 
		  description:(NSString *)description 
		failureReason:(NSString *)failureReason;

+ (id)gg_errorWithDomain:(NSString *)domain
				 code:(NSInteger)code 
		  description:(NSString *)description 
		failureReason:(NSString *)failureReason
	  underlyingError:(NSError *)error;


@end
