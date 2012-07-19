//
//  GGHTTPFetcher.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGHTTPFetcher.h"

@implementation GGHTTPFetcher

@synthesize authorizer = _authorizer;
@synthesize properties = _properties;

+ (id)fetcherWithRequest:(NSURLRequest *)request {
	return [[self alloc] initWithRequest:request];
}

- (id)initWithRequest:(NSURLRequest *)request {
	self = [super init];
	if (self) {
		
	}
	return self;
}

- (BOOL)beginFetchWithDelegate:(NSObject <GGHTTPFetcherDelegate> *)delegate {
	return NO;
}

- (BOOL)beginFetchWithCompletionHandler:(void (^)(NSData *data, NSError *error))handler {
	return NO;
}

- (BOOL)isFetching {
	return NO;
}

- (void)stopFetching {
	
}

- (void)setProperty:(id)value forKey:(NSString *)key {
	
}

- (id)propertyForKey:(NSString *)key {
	return nil;
}

- (NSMutableURLRequest *)mutableRequest {
	return nil;
}

- (NSURLResponse *)response {
	return nil;
}

- (NSInteger)statusCode {
	return 0;
}

@end
