//
//  GGQuery.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGQuery.h"

#import "GGQueryBodyDecoder.h"
#import "GGQueryBodyEncoder.h"

#import <objc/runtime.h>
#import <objc/message.h>

NSString * const GGQueryHTTPMethodGET		= @"GET";
NSString * const GGQueryHTTPMethodPUT		= @"PUT";
NSString * const GGQueryHTTPMethodPOST		= @"POST";
NSString * const GGQueryHTTPMethodPATCH		= @"PATCH";
NSString * const GGQueryHTTPMethodDELETE	= @"DELETE";

@implementation GGQuery {
	NSMutableDictionary *httpHeaders_;
	NSMutableDictionary *queryParameters_;
	NSMutableArray *queryPathComponents_;
}

@synthesize methodName=methodName_;
@synthesize url=url_;

@synthesize bodyDecoder=bodyDecoder_;
@synthesize bodyEncoder=bodyEncoder_;
@synthesize bodyObject=bodyObject_;

@synthesize httpMethod=httpMethod_;
@synthesize etag=etag_;
@synthesize lastModified=lastModified_;
@synthesize httpHeaders=httpHeaders_;
@synthesize queryParameters=queryParameters_;
@synthesize queryPathComponents=queryPathComponents_;

@synthesize suppressAuthorization=suppressAuthorization_;

@synthesize expectedResultClass=expectedResultClass_;

@synthesize revalidateInterval=validateAfter_;
@synthesize cachePersistently=cachePersistently_;

+ (id)queryForMethodName:(NSString *)methodName {
	GGQuery *query = [[[self class] alloc] init];
	query.methodName = methodName;
	return query;
}

+ (id)queryForURL:(NSURL *)url {
	return [self queryForURL:url revalidateInterval:0.0];
}

+ (id)queryForURL:(NSURL *)url revalidateInterval:(NSTimeInterval)revalidateInterval {
	GGQuery *query = [[[self class] alloc] init];
	query.url = url;
	query.revalidateInterval = revalidateInterval;
	return query;
}

#pragma mark -

- (id)init {
	self = [super init];
	if (self) {
		validateAfter_ = 0.0;
	}
	return self;
}


#pragma mark -

- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key {
	if (!key) {
		return;
	}
		
	if (parameter) {
		if (!queryParameters_) {
			queryParameters_ = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		[queryParameters_ setObject:parameter forKey:key];
	} else {
		[queryParameters_ removeObjectForKey:key];
	}
}

- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key {
	if (!key) {
		return;
	}
		
	if (parameter) {
		if (!httpHeaders_) {
			httpHeaders_ = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		[httpHeaders_ setObject:parameter forKey:key];
	} else {
		[httpHeaders_ removeObjectForKey:key];
	}
}

- (void)addQueryPathComponent:(NSString *)component {
	if (!component) {
		return;
	}
	
	if (!queryPathComponents_) {
		queryPathComponents_ = [[NSMutableArray alloc] initWithCapacity:1];
	}
	[queryPathComponents_ addObject:component];
}

#pragma mark -

- (void)setHttpHeaders:(NSDictionary *)httpHeaders {
	id tmp = nil;
	if (httpHeaders) {
		tmp = [[NSMutableDictionary alloc] initWithDictionary:httpHeaders];
	}
	httpHeaders_ = tmp;
}

- (void)setQueryParameters:(NSDictionary *)queryParameters {
	id tmp = nil;
	if (queryParameters) {
		tmp = [[NSMutableDictionary alloc] initWithDictionary:queryParameters];
	}
	queryParameters_ = tmp;
}

- (void)setQueryPathComponents:(NSArray *)queryPathComponents {
	id tmp = nil;
	if (queryPathComponents) {
		tmp = [[NSMutableArray alloc] initWithArray:queryPathComponents];
	}
	queryPathComponents_ = tmp;
}

- (void)setBodyDecoder:(Class)bodyDecoder {
	if (bodyDecoder && !class_conformsToProtocol(bodyDecoder, @protocol(GGQueryBodyDecoder))) {
		return;
	}
	
	bodyDecoder_ = bodyDecoder;
}

- (void)setBodyEncoder:(Class)bodyEncoder {
	if (bodyEncoder && !class_conformsToProtocol(bodyEncoder, @protocol(GGQueryBodyEncoder))) {
		return;
	}
	
	bodyEncoder_ = bodyEncoder;
}

@end
