//
//  GGHTTPQuery.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPQuery.h"

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"

#import <objc/runtime.h>
#import <objc/message.h>

NSString * const GGHTTPQueryMethodGET		= @"GET";
NSString * const GGHTTPQueryMethodPUT		= @"PUT";
NSString * const GGHTTPQueryMethodPOST		= @"POST";
NSString * const GGHTTPQueryMethodPATCH		= @"PATCH";
NSString * const GGHTTPQueryMethodDELETE	= @"DELETE";

@implementation GGHTTPQuery {
	NSMutableDictionary *_httpHeaders;
	NSMutableDictionary *_queryParameters;
	NSMutableArray *_queryPathComponents;
	
	NSMutableDictionary *_properties;
}

@synthesize methodName=_methodName;
@synthesize url=_url;

@synthesize bodyDecoder=_bodyDecoder;
@synthesize bodyEncoder=_bodyEncoder;
@synthesize bodyObject=_bodyObject;

@synthesize httpMethod=_httpMethod;
@synthesize etag=_etag;
@synthesize lastModified=_lastModified;
@synthesize httpHeaders=_httpHeaders;
@synthesize queryParameters=_queryParameters;
@synthesize queryPathComponents=_queryPathComponents;

@synthesize suppressAuthorization=_suppressAuthorization;

@synthesize expectedResultClass=_expectedResultClass;

@synthesize revalidateInterval=_validateAfter;
@synthesize cachePersistently=_cachePersistently;

+ (id)queryForMethodName:(NSString *)methodName {
	GGHTTPQuery *query = [[[self class] alloc] init];
	query.methodName = methodName;
	return query;
}

+ (id)queryForURL:(NSURL *)url {
	GGHTTPQuery *query = [[[self class] alloc] init];
	query.url = url;
	return query;
}

#pragma mark -

- (id)init {
	self = [super init];
	if (self) {
		_validateAfter = 0.0;
	}
	return self;
}


#pragma mark -

- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key {
	if (!key) {
		return;
	}
		
	if (parameter) {
		if (!_queryParameters) {
			_queryParameters = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		[_queryParameters setObject:parameter forKey:key];
	} else {
		[_queryParameters removeObjectForKey:key];
	}
}

- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key {
	if (!key) {
		return;
	}
		
	if (parameter) {
		if (!_httpHeaders) {
			_httpHeaders = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		[_httpHeaders setObject:parameter forKey:key];
	} else {
		[_httpHeaders removeObjectForKey:key];
	}
}

- (void)addQueryPathComponent:(NSString *)component {
	if (!component) {
		return;
	}
	
	if (!_queryPathComponents) {
		_queryPathComponents = [[NSMutableArray alloc] initWithCapacity:1];
	}
	[_queryPathComponents addObject:component];
}

#pragma mark -

- (void)setProperty:(id)obj forKey:(NSString *)key {
	if (!key) {
		return;
	}
	
	if (obj) {
		if (!_properties) {
			_properties = [[NSMutableDictionary alloc] initWithCapacity:5];
		}
		[_properties setObject:obj forKey:key];
	} else {
		[_properties removeObjectForKey:key];
	}
}

- (id)propertyForKey:(NSString *)key {
	return [_properties objectForKey:key];
}

#pragma mark -

- (void)setHttpHeaders:(NSDictionary *)httpHeaders {
	id tmp = nil;
	if (httpHeaders) {
		tmp = [[NSMutableDictionary alloc] initWithDictionary:httpHeaders];
	}
	_httpHeaders = tmp;
}

- (void)setQueryParameters:(NSDictionary *)queryParameters {
	id tmp = nil;
	if (queryParameters) {
		tmp = [[NSMutableDictionary alloc] initWithDictionary:queryParameters];
	}
	_queryParameters = tmp;
}

- (void)setQueryPathComponents:(NSArray *)queryPathComponents {
	id tmp = nil;
	if (queryPathComponents) {
		tmp = [[NSMutableArray alloc] initWithArray:queryPathComponents];
	}
	_queryPathComponents = tmp;
}

- (void)setBodyDecoder:(Class)bodyDecoder {
	if (bodyDecoder && !class_conformsToProtocol(bodyDecoder, @protocol(GGHTTPQueryBodyDecoder))) {
		return;
	}
	
	_bodyDecoder = bodyDecoder;
}

- (void)setBodyEncoder:(Class)bodyEncoder {
	if (bodyEncoder && !class_conformsToProtocol(bodyEncoder, @protocol(GGHTTPQueryBodyEncoder))) {
		return;
	}
	
	_bodyEncoder = bodyEncoder;
}

@end
