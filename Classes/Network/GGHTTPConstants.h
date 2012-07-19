//
//  GGHTTPConstants.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kGGHTTPFetcherErrorDomain;
extern NSString * const kGGHTTPFetcherStatusDomain;
extern NSString * const kGGHTTPServiceErrorDomain;

enum {
	kGGHTTPServiceErrorInvalidResponseData		= -1,
	kGGHTTPServiceErrorUnauthorized				= -2,
	kGGHTTPServiceErrorInvalidRequestBody		= -3,
	kGGHTTPServiceErrorUnableToConstructRequest = -4
};

enum {
	kGGHTTPFetcherErrorDownloadFailed = -1,
	kGGHTTPFetcherErrorAuthenticationChallengeFailed = -2,
	kGGHTTPFetcherErrorBackgroundExpiration = -3,
	
	kGGHTTPFetcherStatusNotModified = 304,
	kGGHTTPFetcherStatusBadRequest = 400,
	kGGHTTPFetcherStatusUnauthorized = 401,
	kGGHTTPFetcherStatusForbidden = 403,
	kGGHTTPFetcherStatusPreconditionFailed = 412
};

extern NSString * const kGGHTTPAuthorizationErrorDomain;
extern NSString * const kGGHTTPAuthorizationErrorRequestKey;

enum {
	kGGHTTPAuthorizationErrorAuthorizationFailed = -1001
};

