//
//  GGHTTPQueryResult.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPQueryResult.h"

#import "GGHTTPQuery.h"

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"
#import "GGHTTPQueryBodyJSONTransformer.h"

#import "GGHTTPCacheItem.h"

#import "GGHTTPConstants.h"

#import "NSError+GGExtra.h"

@implementation GGHTTPQueryResult {
	id _data;
	BOOL _processedRawData;
	
	NSDictionary *_responseHeaders;
}


+ (id)queryResultWithError:(NSError *)error {
	GGHTTPQueryResult *result = [[[self class] alloc] init];
	result.error = error;
	return result;
}

- (NSDictionary *)responseHeaders {
	if ([self isCached]) {
		return [self.cacheItem responseHeaders];
	} else {
		return _responseHeaders;
	}
}

- (void)setResponseHeaders:(NSDictionary *)rawHeaders {
	NSMutableDictionary *responseHeaders = nil;
	
	if (rawHeaders && [rawHeaders count] > 0) {
		responseHeaders = [NSMutableDictionary dictionaryWithCapacity:[rawHeaders count]];
		[rawHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[responseHeaders setObject:obj forKey:[key lowercaseString]];
		}];
	}
	
	_responseHeaders = responseHeaders;
}

- (id)data {
	if (!_processedRawData) {
		[self processRawData];
	}
	
	return _data;
}

- (NSData *)rawData {
	if ([self isCached]) {
		return self.cacheItem.data;
	} else {
		return _rawData;
	}
}

- (NSError *)error {
	if (!_error && !_processedRawData && ![self isCached]) {
		[self processRawData];
	}
	
	return _error;
}

- (BOOL)isCached {
	return (_cacheItem != nil);
}

- (void)processRawData {
	if (_processedRawData) {
		return;
	}
	
	_processedRawData = YES;
	
	if (_error) {
		_data = [self objectWithData:_rawData
						 contentType:[self contentType]
							 decoder:nil
					   expectedClass:[NSDictionary class]
							   error:nil];
	} else {
		NSError *error = nil;
		
		_data = [self objectWithData:[self rawData]
						 contentType:[self contentType]
							 decoder:self.query.bodyDecoder
					   expectedClass:self.query.expectedResultClass
							   error:&error];
		
		if (error && ![self isCached]) {
			_error = error;
		}
	}
}

- (id)objectWithData:(NSData *)data
		 contentType:(NSString *)contentType
			 decoder:(Class)decoder
	   expectedClass:(Class)expectedClass
			   error:(NSError **)error {
	
	if (!data || [data length] == 0) {
		return nil;
	}
	
	id result = nil;
	
	if (!decoder && contentType) {
		if ([contentType caseInsensitiveCompare:@"application/json"] == NSOrderedSame) {
			decoder = [GGHTTPQueryBodyJSONTransformer class];
		}
	}
	
	if (decoder) {
		result = [decoder decode:data error:error];
		if (error && *error) {
			return nil;
		}
		
		if (expectedClass && ![result isKindOfClass:expectedClass]) {
			if (error) {
				*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
											 code:kGGHTTPServiceErrorInvalidResponseData
									  description:NSLocalizedString(@"Error", nil)
									failureReason:nil];
			}
			return nil;
		}
		
	} else {
		Class imageClass = NSClassFromString(@"UIImage");
		if (imageClass && expectedClass == imageClass && [contentType hasPrefix:@"image/"]) {
			result = [[imageClass alloc] initWithData:data];
		}

		if (!result) {
			result = data;
		}
	}
	
	return result;
}

- (NSString *)contentType {
	return [[self responseHeaders] objectForKey:@"content-type"];
}


@end
