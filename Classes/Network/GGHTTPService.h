//
//  GGHTTPService.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPServiceTicket;

@class GGHTTPQuery;
@class GGHTTPQueryResult;
@class GGHTTPQueryBody;

typedef void (^GGHTTPServiceCompletionHandler)(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult);

@protocol GGHTTPAuthorizationProtocol;
@protocol GGHTTPCacheProtocol;

@interface GGHTTPService : NSObject

+ (id)sharedService;

+ (Class)fetcherClass;
+ (void)setFetcherClass:(Class)fetcherClass;

- (id)initWithBaseURL:(NSURL *)baseURL;

#pragma mark -

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			   completionHandler:(GGHTTPServiceCompletionHandler)handler;

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
					completionHandler:(GGHTTPServiceCompletionHandler)handler;

- (void)cancelQueryWithTicket:(GGHTTPServiceTicket *)ticket;

#pragma mark -

- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key;

@property(nonatomic, strong) NSURL *baseURL;

@property(nonatomic, strong) NSObject <GGHTTPCacheProtocol> *cache;
@property(nonatomic, strong) NSObject <GGHTTPCacheProtocol> *persistentCache;

@property(nonatomic, strong) NSObject <GGHTTPAuthorizationProtocol> *authorizer;


#pragma mark -

- (NSURL *)requestURLForQuery:(GGHTTPQuery *)query;
- (NSURL *)URLForQuery:(GGHTTPQuery *)query;

- (NSMutableURLRequest *)requestForQuery:(GGHTTPQuery *)query;
- (GGHTTPQueryBody *)requestBodyForQuery:(GGHTTPQuery *)query error:(NSError **)error;

@end
