//
//  GGQueryBodyJSONTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGQueryBodyJSONTransformer.h"
#import "GGQueryBody.h"

#import "GGHTTPService.h"

#import "SBJsonWriter.h"
#import "SBJsonParser.h"

#import "NSError+Extra.h"

@implementation GGQueryBodyJSONTransformer

+ (id)decode:(NSData *)data error:(NSError **)error {	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	id object = [parser objectWithData:data];
	if (!object) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidResponseData 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:parser.error];
		}
	}
		
	return object;
}

+ (GGQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
		
	SBJsonWriter *writer = [[SBJsonWriter alloc] init];
	NSData *data = [writer dataWithObject:bodyObject];
	
	if (!data || [data length] == 0) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidRequestBody 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:writer.error];
		}
		return nil;
	}
	
	GGQueryBody *body = [[GGQueryBody alloc] init];
	body.data = data;
	body.contentType = @"application/json";
	
	return body;
}

@end
