//
//  GGDataManager.h
//
//  Created by Evgeniy Shurakov on 7/31/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGDataStorage;
@class GGHTTPService;
@class GGHTTPQuery;
@class GGHTTPQueryResult;
@class GGResourceConfig;
@class GGDataManagerTicket;

@interface GGDataManager : NSObject

@property (nonatomic, readonly, strong) GGHTTPService *apiService;
@property (nonatomic, readonly, strong) GGDataStorage *dataStorage;

- (id)initWithDataStorage:(GGDataStorage *)dataStorage
			   apiService:(GGHTTPService *)apiService;

#pragma mark -

- (void)cancelAllTasks;
- (void)cancelTaskWithTicket:(id)ticket;

#pragma mark -

- (GGHTTPQuery *)queryWithRelativePath:(NSString *)methodName;

#pragma mark -

- (id)executeQuery:(GGHTTPQuery *)query
	  clientTicket:(GGDataManagerTicket *)clientTicket
 completionHandler:(void (^)(GGHTTPQueryResult *result, NSArray *clientTickets))handler;

- (id)loadObjectsWithQuery:(GGHTTPQuery *)query
			resourceConfig:(GGResourceConfig *)config
		 completionHandler:(void (^)(NSArray *objects, NSError *error))handler;

@end
