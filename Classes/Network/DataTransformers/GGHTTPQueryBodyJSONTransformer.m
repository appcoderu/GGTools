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

#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@implementation GGHTTPQueryBodyJSONTransformer

+ (id)decode:(NSData *)data error:(NSError **)error {
	NSError *jsonError = nil;
	id object = nil;
	
	Class jsonSerializaionClass = nil;
	if ((jsonSerializaionClass = NSClassFromString(@"NSJSONSerialization"))) {
		object = [jsonSerializaionClass JSONObjectWithData:data
												   options:0
													 error:&jsonError];
		if (jsonError && error) {
			*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
											code:kGGHTTPServiceErrorInvalidResponseData
									 description:NSLocalizedString(@"Error", nil)
								   failureReason:jsonError.localizedFailureReason
								 underlyingError:jsonError];
		}
	} else if ((jsonSerializaionClass = NSClassFromString(@"SBJsonParser"))) {
		id jsonSerializaionObj = [[jsonSerializaionClass alloc] init];
		object = [jsonSerializaionObj objectWithData:data];
		if (!object && error) {
			*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
											code:kGGHTTPServiceErrorInvalidResponseData
									 description:NSLocalizedString(@"Error", nil)
								   failureReason:(NSString *)[jsonSerializaionObj error]];
		}
	} else {
		NSAssert(false, @"JSON parser not found (NSJSONSerialization or SBJsonParser)");
	}
	
	return object;
}

+ (GGHTTPQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	NSData *data = nil;
	
	Class jsonSerializaionClass = nil;
	if ((jsonSerializaionClass = NSClassFromString(@"NSJSONSerialization"))) {
		NSError *jsonError = nil;
		data = [jsonSerializaionClass dataWithJSONObject:bodyObject
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
	} else if ((jsonSerializaionClass = NSClassFromString(@"SBJsonWriter"))) {
		id jsonSerializaionObj = [[jsonSerializaionClass alloc] init];
		data = [jsonSerializaionObj dataWithObject:bodyObject];
		if (!data || [data length] == 0) {
			if (error) {
				*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
												code:kGGHTTPServiceErrorInvalidRequestBody
										 description:NSLocalizedString(@"Error", nil)
									   failureReason:(NSString *)[jsonSerializaionObj error]];
			}
			return nil;
		}
	} else {
		NSAssert(false, @"JSON writer not found (NSJSONSerialization or SBJsonWriter)");
		return nil;
	}

	GGHTTPQueryBody *body = [[GGHTTPQueryBody alloc] init];
	body.data = data;
	body.contentType = @"application/json";
	
	return body;
}

@end
