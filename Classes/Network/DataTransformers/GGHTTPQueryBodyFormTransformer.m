//
//  GGHTTPQueryBodyFormTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPQueryBodyFormTransformer.h"

#import "GGHTTPConstants.h"
#import "GGHTTPQueryBody.h"

#import "NSError+Extra.h"
#import "NSDictionary+URL.h"

@implementation GGHTTPQueryBodyFormTransformer

+ (GGHTTPQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	if (![bodyObject isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
										 code:kGGHTTPServiceErrorInvalidRequestBody
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}
	
	GGHTTPQueryBody *body = [[GGHTTPQueryBody alloc] init];
	body.data = [[bodyObject componentsAsParameterString] dataUsingEncoding:NSUTF8StringEncoding];
	body.contentType = @"application/x-www-form-urlencoded";
	
	return body;
}

@end
