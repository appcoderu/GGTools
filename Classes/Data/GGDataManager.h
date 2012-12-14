//
//  GGDataManager.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 7/31/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGDataMapper;
@class GGHTTPService;
@class GGHTTPServiceTicket;
@class GGHTTPQuery;
@class GGHTTPQueryResult;
@class GGResourceConfig;

@interface GGDataManager : NSObject

@property (nonatomic, readonly, strong) GGHTTPService *apiService;
@property (nonatomic, readonly, strong) GGDataMapper *dataMapper;

- (id)initWithAPIService:(GGHTTPService *)apiService
			  dataMapper:(GGDataMapper *)dataMapper;

#pragma mark -

- (void)cancelAllTasks;
- (void)cancelTaskWithTicket:(GGHTTPServiceTicket *)ticket;

#pragma mark -

- (GGHTTPQuery *)queryWithRelativePath:(NSString *)methodName;

#pragma mark -

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
					completionHandler:(void (^)(GGHTTPQueryResult *result))handler;

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
					   resourceConfig:(GGResourceConfig *)config
					completionHandler:(void (^)(id mappedObjects, NSError *error))handler;

#pragma mark - Methods to override

- (void)handleAuthorizationErrorForQuery:(GGHTTPQuery *)query;
- (NSError *)errorWithQueryResultData:(NSDictionary *)data;

@end
