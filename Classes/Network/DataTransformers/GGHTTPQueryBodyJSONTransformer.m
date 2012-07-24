//
//  GGHTTPQueryBodyJSONTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPQueryBodyJSONTransformer.h"
#import "GGHTTPQueryBody.h"

#import "GGHTTPConstants.h"

#import "NSError+GGExtra.h"

@implementation GGHTTPQueryBodyJSONTransformer

+ (id)decode:(NSData *)data error:(NSError **)error {
	NSError *jsonError = nil;
	id object = [NSJSONSerialization JSONObjectWithData:data
												options:0
												  error:&jsonError];
	
	if (jsonError && error) {
		*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
										code:kGGHTTPServiceErrorInvalidResponseData
								 description:NSLocalizedString(@"Error", nil)
							   failureReason:jsonError.localizedFailureReason
							 underlyingError:jsonError];
	}
	
	return object;
}

+ (GGHTTPQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	NSError *jsonError = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:bodyObject
												   options:0
													 error:&jsonError];
	
	if (jsonError) {
		if (error) {
			*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
											code:kGGHTTPServiceErrorInvalidRequestBody
									 description:NSLocalizedString(@"Error", nil)
								   failureReason:jsonError.localizedFailureReason
								 underlyingError:jsonError];
		}
		return nil;
	}
	
	GGHTTPQueryBody *body = [[GGHTTPQueryBody alloc] init];
	body.data = data;
	body.contentType = @"application/json";
	
	return body;
}

@end
