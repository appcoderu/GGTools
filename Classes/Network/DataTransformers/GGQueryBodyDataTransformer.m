//
//  GGQueryBodyDataTransformer.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGQueryBodyDataTransformer.h"

#import "GGQueryBody.h"
#import "GGHTTPService.h"
#import "NSError+Extra.h"

@implementation GGQueryBodyDataTransformer

+ (id)decode:(NSData *)data error:(NSError **)error {
	return data;
}

+ (GGQueryBody *)encode:(id)bodyObject error:(NSError **)error {
	if (!bodyObject) {
		return nil;
	}
	
	if (![bodyObject isKindOfClass:[NSData class]]) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidRequestBody 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}
		
	GGQueryBody *body = [[GGQueryBody alloc] init];
	body.data = bodyObject;
	body.contentType = @"application/octet-stream";
	
	return body;
}

@end
