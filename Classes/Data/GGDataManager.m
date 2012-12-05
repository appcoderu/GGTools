//
//  GGDataManager.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 7/31/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGDataManager.h"

#import "GGHTTPConstants.h"

#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"

#import "GGHTTPQuery.h"
#import "GGHTTPQueryResult.h"

#import "GGDataMapper.h"
#import "GGResourceConfig.h"

#import "NSError+GGExtra.h"

@implementation GGDataManager {
	NSMutableArray *tickets;
}

- (id)init {
	return [self initWithAPIService:nil dataMapper:nil];
}

- (id)initWithAPIService:(GGHTTPService *)apiService
			  dataMapper:(GGDataMapper *)dataMapper {
    self = [super init];
    if (self) {
		_apiService = apiService;
		_dataMapper = dataMapper;
		
        tickets = [[NSMutableArray alloc] initWithCapacity:20];
    }
    return self;
}

#pragma mark - Tickets

- (void)cancelAllTasks {
	for (GGHTTPServiceTicket *ticket in tickets) {
		[_apiService cancelQueryWithTicket:ticket];
	}

	[tickets removeAllObjects];
}

- (void)cancelTaskWithTicket:(GGHTTPServiceTicket *)ticket {
	[_apiService cancelQueryWithTicket:ticket];
	[self removeTicket:ticket];
}

- (void)addTicket:(GGHTTPServiceTicket *)ticket {
	if (!ticket) {
		return;
	}
	[tickets addObject:ticket];
}

- (void)removeTicket:(GGHTTPServiceTicket *)ticket {
	if (!ticket) {
		return;
	}
	[tickets removeObject:ticket];
}

#pragma mark - API Requests

- (void)handleAuthorizationErrorForQuery:(GGHTTPQuery *)query {
	// default implementation did nothing
}

- (NSError *)errorWithQueryResultData:(NSDictionary *)data {
	if (![data isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
	
	id error = [data objectForKey:@"error"];
	NSString *errorStr = nil;
	if ([error isKindOfClass:[NSString class]]) {
		errorStr = error;
	} else if ([error isKindOfClass:[NSArray class]]) {
		errorStr = [error componentsJoinedByString:@"\n"];
	}
	
	if (!errorStr) {
		return nil;
	}
	
	return [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
								  code:0
						   description:NSLocalizedString(@"Error", nil)
						 failureReason:errorStr
					   underlyingError:nil];
}


- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
					completionHandler:(void (^)(GGHTTPQueryResult *result))handler {
	if (!query || !handler) {
		return nil;
	}
				
	id serviceCompletionHandler = ^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *result) {
		if (result.error) {		
			if (result.error.domain == kGGHTTPAuthorizationErrorDomain ||
				(result.error.domain == kGGHTTPFetcherStatusDomain && result.error.code == kGGHTTPFetcherStatusUnauthorized)) {
				[self handleAuthorizationErrorForQuery:result.query];
			}
			
			if (result.error.domain == kGGHTTPFetcherStatusDomain) {
				NSError *error = [self errorWithQueryResultData:result.data];
				if (error) {
					result.error = error;
				}
			}
		}
		
		handler(result);
	};
		
	GGHTTPServiceTicket *apiTicket = [self.apiService executeQuery:query
												 completionHandler:serviceCompletionHandler];
	
	if (apiTicket && !apiTicket.used) {
		[self addTicket:apiTicket];
	}
	
	return apiTicket;
}

#pragma mark -

- (GGHTTPServiceTicket *)loadObjectsWithQuery:(GGHTTPQuery *)query
							   resourceConfig:(GGResourceConfig *)config
							completionHandler:(void (^)(id objects, NSError *error))handler {
	
	return [self executeQuery:query
			completionHandler:^(GGHTTPQueryResult *result) {
				id objects = nil;
				if (!result.error && !result.cached) {
					NSError *error = nil;
					objects = [self.dataMapper mapData:result.data
										resourceConfig:config
												 error:&error];
					result.error = error;
					
					if (error) {
						NSLog(@"%@", error);
					}
				}
				
				if (handler) {
					handler(objects, result.error);
				}
			}];
}

#pragma mark -

- (GGHTTPQuery *)queryWithRelativePath:(NSString *)methodName {
	return [GGHTTPQuery queryWithRelativePath:methodName];
}

@end
