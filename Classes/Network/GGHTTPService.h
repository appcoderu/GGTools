//
//  GGHTTPService.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kGGHTTPServiceErrorDomain;

enum {
	kGGHTTPServiceErrorInvalidResponseData		= -1,
	kGGHTTPServiceErrorQueryFailed				= -2,
	kGGHTTPServiceErrorUnauthorized				= -3,
	kGGHTTPServiceErrorInvalidRequestBody		= -4,
	kGGHTTPServiceErrorUnableToConstructRequest = -5
};

@class GGHTTPServiceTicket;

@class GGHTTPQuery;
@class GGCache;
@class GGCacheItem;

@protocol GGHTTPAuthorizationProtocol;
@protocol GGHTTPCacheProtocol;

@interface GGHTTPService : NSObject

+ (id)sharedService;

- (id)initWithBaseURL:(NSURL *)baseURL;

#pragma mark -

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler;

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			  revalidateInterval:(NSTimeInterval)revalidateInterval
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler;

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
					completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler;

- (void)cancelQueryWithTicket:(GGHTTPServiceTicket *)ticket;

#pragma mark -

@property(nonatomic, strong) NSString *userAgent;
@property(nonatomic, strong) NSURL *baseURL;
@property(nonatomic, copy) NSDictionary *additionalHTTPHeaders;

@property(nonatomic, strong) NSObject <GGHTTPCacheProtocol> *cache;
@property(nonatomic, strong) NSObject <GGHTTPCacheProtocol> *persistentCache;

@property(nonatomic, strong) NSObject <GGHTTPAuthorizationProtocol> *authorizer;

@end
