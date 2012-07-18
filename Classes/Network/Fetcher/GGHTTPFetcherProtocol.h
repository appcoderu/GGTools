//
//  GGHTTPFetcherProtocol.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 18.07.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

NSString * const kGGHTTPFetcherErrorDomain = @"ru.appcode.http.error";
NSString * const kGGHTTPFetcherStatusDomain = @"ru.appcode.http.status";

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

@protocol GGAuthorizationProtocol;

@protocol GGHTTPFetcherProtocol <NSObject>

@property(nonatomic, strong) NSObject <GGAuthorizationProtocol> *authorizer;
@property(nonatomic, copy) NSMutableDictionary *properties;

@property(nonatomic, strong, readonly) NSURLRequest *request;
@property(nonatomic, strong, readonly) NSHTTPURLResponse *response;

@property (nonatomic, assign, readonly) NSInteger statusCode;

- (BOOL)beginFetchWithDelegate:(id)delegate
             didFinishSelector:(SEL)finishedSEL;

- (BOOL)beginFetchWithCompletionHandler:(void (^)(NSData *data, NSError *error))handler;

- (BOOL)isFetching;
- (void)stopFetching;

- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

@end
