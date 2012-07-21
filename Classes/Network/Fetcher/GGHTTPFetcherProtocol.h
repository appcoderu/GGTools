//
//  GGHTTPFetcherProtocol.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGHTTPAuthorizationProtocol;
@protocol GGHTTPFetcherDelegate;

@protocol GGHTTPFetcherProtocol <NSObject>

@property(nonatomic, strong) NSObject <GGHTTPAuthorizationProtocol> *authorizer;
@property(nonatomic, copy) NSMutableDictionary *properties;

@property(nonatomic, strong, readonly) NSMutableURLRequest *mutableRequest;
@property(nonatomic, strong, readonly) NSURLResponse *response;

@property(nonatomic, assign, readonly) NSInteger statusCode;

@property(nonatomic, assign, getter = isRetryEnabled) BOOL retryEnabled;
@property(nonatomic, assign) NSTimeInterval maxRetryInterval;

+ (id)fetcherWithRequest:(NSURLRequest *)request;
- (id)initWithRequest:(NSURLRequest *)request;

- (BOOL)beginFetchWithDelegate:(NSObject <GGHTTPFetcherDelegate> *)delegate;
- (BOOL)beginFetchWithCompletionHandler:(void (^)(NSData *data, NSError *error))handler;

- (BOOL)isFetching;
- (void)stopFetching;

- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

@end
