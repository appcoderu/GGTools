//
//  GGHTTPGoogleFetcher.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPGoogleFetcher.h"
#import "GGHTTPFetcherDelegate.h"
#import "GGHTTPConstants.h"

#import "GTMHTTPFetcher.h"

#import "GGHTTPGoogleAuthorizationProxy.h"

#import "NSError+GGExtra.h"

@implementation GGHTTPGoogleFetcher {
	GTMHTTPFetcher *_fetcher;
	
	void (^_completionHandler)(NSData *data, NSError *error);
	__weak NSObject <GGHTTPFetcherDelegate> *_delegate;
}

+ (id)fetcherWithRequest:(NSURLRequest *)request {
	return [[self alloc] initWithRequest:request];
}

- (id)initWithRequest:(NSURLRequest *)request {
	self = [super init];
	if (self) {
		_fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
		_fetcher.cookieStorageMethod = kGTMHTTPFetcherCookieStorageMethodNone;
	}
	return self;
}

- (void)dealloc {
    [self stopFetching];
}

- (BOOL)beginFetchWithDelegate:(NSObject <GGHTTPFetcherDelegate> *)delegate {
	
	if (!delegate) {
		return NO;
	}
	
	_delegate = delegate;
	
	return [self beginFetch];
}

- (BOOL)beginFetchWithCompletionHandler:(void (^)(NSData *data, NSError *error))handler {

	if (!handler) {
		return NO;
	}
	
	_completionHandler = [handler copy];
	
	return [self beginFetch];
}

- (BOOL)beginFetch {
	return [_fetcher beginFetchWithDelegate:self
						  didFinishSelector:@selector(fetcher:finishedWithData:error:)];
}

- (BOOL)isFetching {
	return [_fetcher isFetching];
}

- (void)stopFetching {
	[_fetcher stopFetching];
	[self releaseCallbacks];
}

- (NSObject <GGHTTPAuthorizationProtocol> *)authorizer {
	if ([_fetcher.authorizer isKindOfClass:[GGHTTPGoogleAuthorizationProxy class]]) {
		return [(GGHTTPGoogleAuthorizationProxy *)(_fetcher.authorizer) authorizer];
	}
	
	return nil;
}

- (void)setAuthorizer:(NSObject<GGHTTPAuthorizationProtocol> *)authorizer {
	if (!authorizer) {
		_fetcher.authorizer = nil;
		return;
	}
	
	_fetcher.authorizer = [[GGHTTPGoogleAuthorizationProxy alloc] initWithAuthorizer:authorizer];
}

- (NSMutableDictionary *)properties {
	return [_fetcher properties];
}

- (void)setProperties:(NSMutableDictionary *)properties {
	[_fetcher setProperties:properties];
}

- (void)setProperty:(id)value forKey:(NSString *)key {
	[_fetcher setProperty:value forKey:key];
}

- (id)propertyForKey:(NSString *)key {
	return [_fetcher propertyForKey:key];
}

- (NSMutableURLRequest *)mutableRequest {
	return [_fetcher mutableRequest];
}

- (NSURLResponse *)response {
	return [_fetcher response];
}

- (NSInteger)statusCode {
	return [_fetcher statusCode];
}

- (BOOL)isRetryEnabled {
	return [_fetcher isRetryEnabled];
}

- (void)setRetryEnabled:(BOOL)retryEnabled {
	[_fetcher setRetryEnabled:retryEnabled];
}

- (NSTimeInterval)maxRetryInterval {
	return [_fetcher maxRetryInterval];
}

- (void)setMaxRetryInterval:(NSTimeInterval)maxRetryInterval {
	[_fetcher setMaxRetryInterval:maxRetryInterval];
}

- (void)releaseCallbacks {
	_delegate = nil;	
	_completionHandler = nil;
}

#pragma mark -

- (void)fetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
	
	error = [self errorWithGoogleError:error];
	
	if (_delegate) {
		[_delegate fetcher:self
		  finishedWithData:data
					 error:error];
	}
	
	if (_completionHandler) {
		_completionHandler(data, error);
	}
	
	[self releaseCallbacks];
	_fetcher = nil;
}

- (NSError *)errorWithGoogleError:(NSError *)error {
	if (!error) {
		return nil;
	}
	
	NSString *domain = nil;
	NSInteger code = 0;
	
	NSError *underlyingError = nil;
	
	if ([[error domain] isEqualToString:kGTMHTTPFetcherErrorDomain]) {
		domain = kGGHTTPFetcherErrorDomain;
		if ([error code] == kGTMHTTPFetcherErrorAuthenticationChallengeFailed) {
			code = kGGHTTPFetcherErrorAuthenticationChallengeFailed;
		} else if ([error code] == kGTMHTTPFetcherErrorBackgroundExpiration) {
			code = kGGHTTPFetcherErrorBackgroundExpiration;
		} else {
			code = kGGHTTPFetcherErrorDownloadFailed;
		}
	} else if ([[error domain] isEqualToString:kGTMHTTPFetcherStatusDomain]) {
		domain = kGGHTTPFetcherStatusDomain;
		code = [error code];
	} else {
		return error;
	}
	
	NSString *description = [underlyingError localizedDescription];
	if (!description) {
		description = NSLocalizedString(@"Error", nil);
	}
	
	NSString *failureReason = [underlyingError localizedFailureReason];
	
	return [NSError gg_errorWithDomain:domain
							   code:code
						description:description
					  failureReason:failureReason
					underlyingError:error];
}

@end
