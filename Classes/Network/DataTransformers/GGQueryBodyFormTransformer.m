//
//  GGQueryBodyFormTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGQueryBodyFormTransformer.h"

#import "GGHTTPService.h"
#import "GGQueryBody.h"

#import "NSError+Extra.h"
#import "NSDictionary+URL.h"

@implementation GGQueryBodyFormTransformer

+ (GGQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	if (![bodyObject isKindOfClass:[NSDictionary class]]) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidRequestBody 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}
	
	GGQueryBody *body = [[GGQueryBody alloc] init];
	body.data = [[bodyObject componentsAsParameterString] dataUsingEncoding:NSUTF8StringEncoding];
	body.contentType = @"application/x-www-form-urlencoded";
	
	return body;
}

@end
