//
//  GGHTTPService.h
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const GGHTTPServiceErrorDomain;

extern const NSInteger GGHTTPServiceErrorUnableToConstructRequest;
extern const NSInteger GGHTTPServiceErrorInvalidResponseData;
extern const NSInteger GGHTTPServiceErrorInvalidRequestBody;
extern const NSInteger GGHTTPServiceErrorQueryFailed;
extern const NSInteger GGHTTPServiceErrorUnauthorized;

@class GGHTTPServiceTicket;

@class GGQuery;
@class GGCache;
@class GGCacheItem;

@protocol GGAuthorizationProtocol;
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

- (GGHTTPServiceTicket *)executeQuery:(GGQuery *)query
					completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler;

- (void)cancelQueryWithTicket:(GGHTTPServiceTicket *)ticket;

#pragma mark -

@property(nonatomic, retain) NSString *userAgent;
@property(nonatomic, retain) NSURL *baseURL;
@property(nonatomic, copy) NSDictionary *additionalHTTPHeaders;

@property(nonatomic, retain) NSObject <GGHTTPCacheProtocol> *cache;
@property(nonatomic, retain) NSObject <GGHTTPCacheProtocol> *persistentCache;

@property(nonatomic, retain) NSObject <GGAuthorizationProtocol> *authorizer;

@end
