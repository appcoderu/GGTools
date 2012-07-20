//
//  GGHTTPQueryBodyDataTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPQueryBodyDataTransformer.h"

#import "GGHTTPQueryBody.h"
#import "GGHTTPConstants.h"

#import "NSError+GGExtra.h"

@implementation GGHTTPQueryBodyDataTransformer

+ (id)decode:(NSData *)data error:(NSError **)error {
	return data;
}

+ (GGHTTPQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	if (![bodyObject isKindOfClass:[NSData class]]) {
		if (error) {
			*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
										 code:kGGHTTPServiceErrorInvalidRequestBody
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}
		
	GGHTTPQueryBody *body = [[GGHTTPQueryBody alloc] init];
	body.data = bodyObject;
	body.contentType = @"application/octet-stream";
	
	return body;
}

@end
