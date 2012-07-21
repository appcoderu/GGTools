//
//  GGHTTPGoogleAuthorizationProxy.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 21.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPGoogleAuthorizationProxy.h"

#import "GGHTTPAuthorizationProtocol.h"

@implementation GGHTTPGoogleAuthorizationProxy

- (id)init {
	return [self initWithAuthorizer:nil];
}

- (id)initWithAuthorizer:(NSObject<GGHTTPAuthorizationProtocol> *)authorizer {
	self = [super init];
	if (self) {
		_authorizer = authorizer;
	}
	return self;
}

- (void)dealloc {
    [self stopAuthorization];
}

#pragma mark -

- (void)authorizeRequest:(NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel {
	[self authorizeRequest:request
				  delegate:delegate
		 didFinishSelector:sel];
}

- (void)stopAuthorization {
	[_authorizer stopAuthorization];
}

- (BOOL)isAuthorizingRequest:(NSURLRequest *)request {
	return [_authorizer isAuthorizingRequest:request];
}

- (BOOL)isAuthorizedRequest:(NSURLRequest *)request {
	return [_authorizer isAuthorizedRequest:request];
}

- (NSString *)userEmail {
	return nil;
}

- (BOOL)primeForRefresh {
	return [_authorizer primeForRefresh];
}

@end
