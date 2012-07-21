//
//  GGNetworkTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGNetworkTest.h"

#import "GGHTTPConstants.h"

#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"

#import "GGHTTPQuery.h"
#import "GGHTTPQueryResult.h"

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"
#import "GGHTTPQueryBodyJSONTransformer.h"

#import "HTTPServer.h"

@implementation GGNetworkTest {
	HTTPServer *httpServer;
}

- (void)setUpClass {
	httpServer = [[HTTPServer alloc] init];
	[httpServer setPort:20005];
	
	NSString *webPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Web"];
	
	[httpServer setDocumentRoot:webPath];
	
	NSError *error;
	BOOL success = [httpServer start:&error];
	
	GHAssertTrue(success, @"Error starting HTTP Server: %@", error);
}

- (void)tearDownClass {
	httpServer = nil;
}

- (void)testSimpleRequest {
	[self prepare];
	
	GGHTTPService *service = [[GGHTTPService alloc] initWithBaseURL:nil];
	GGHTTPServiceTicket *localTicket = nil;
	localTicket = [service loadURL:[NSURL URLWithString:@"http://:20005/index.html"]
   completionHandler:^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult) {
	   GHAssertNotNil(ticket, nil);
	   GHAssertNotNil(ticket.query, nil);
	   GHAssertNil(ticket.fetcher, nil);
	   GHAssertTrue(ticket.used, nil);
	   
	   GHAssertNotNil(queryResult, nil);
	   GHAssertNil(queryResult.error, nil);
	   GHAssertNil(queryResult.cacheItem, nil);
	   GHAssertFalse(queryResult.cached, nil);
	   GHAssertNotNil(queryResult.data, nil);
	   GHAssertNotNil(queryResult.rawData, nil);
	   GHAssertEquals(queryResult.statusCode, (NSInteger)200, nil);
	   
	   GHAssertTrue([queryResult.data isKindOfClass:[NSData class]], nil);
	   
	   GHAssertEqualObjects(queryResult.rawData, [@"123" dataUsingEncoding:NSUTF8StringEncoding], nil);
	   
	   [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSimpleRequest)];
   }];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
	
	service = nil;
	localTicket = nil;
}

- (void)testSimpleMissingRequest {
	[self prepare];
	
	GGHTTPService *service = [[GGHTTPService alloc] initWithBaseURL:nil];
	[service loadURL:[NSURL URLWithString:@"http://:20005/strange_url"]
   completionHandler:^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult) {
	   GHAssertNotNil(queryResult, nil);
	   GHAssertNotNil(queryResult.error, nil);
	   GHAssertEqualObjects(queryResult.error.domain, kGGHTTPFetcherStatusDomain, nil);
	   GHAssertEquals(queryResult.error.code, (NSInteger)404, nil);
	   
	   GHAssertNil(queryResult.cacheItem, nil);
	   GHAssertFalse(queryResult.cached, nil);
	   GHAssertNil(queryResult.data, nil);
	   GHAssertNil(queryResult.rawData, nil);
	   
	   GHAssertEquals(queryResult.statusCode, (NSInteger)404, nil);
	   
	   [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSimpleMissingRequest)];
   }];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
	
	service = nil;
}

- (void)testSimpleQuery {
	[self prepare];
	
	GGHTTPService *service = [[GGHTTPService alloc] initWithBaseURL:nil];
	GGHTTPQuery *query = [GGHTTPQuery queryForURL:[NSURL URLWithString:@"http://:20005/index.html"]];
	
	GGHTTPServiceTicket *localTicket = nil;
	localTicket = [service executeQuery:query
	   completionHandler:^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult) {
		   GHAssertNotNil(ticket, nil);
		   GHAssertNotNil(ticket.query, nil);
		   GHAssertEquals(ticket.query, query, nil);
		   GHAssertNil(ticket.fetcher, nil);
		   GHAssertTrue(ticket.used, nil);
		   
		   GHAssertNotNil(queryResult, nil);
		   GHAssertNil(queryResult.error, nil);
		   GHAssertNil(queryResult.cacheItem, nil);
		   GHAssertFalse(queryResult.cached, nil);
		   GHAssertNotNil(queryResult.data, nil);
		   GHAssertNotNil(queryResult.rawData, nil);
		   GHAssertEquals(queryResult.statusCode, (NSInteger)200, nil);
		   
		   GHAssertTrue([queryResult.data isKindOfClass:[NSData class]], nil);
		   
		   GHAssertEqualObjects(queryResult.rawData, [@"123" dataUsingEncoding:NSUTF8StringEncoding], nil);
		   
		   [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSimpleQuery)];
	   }];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
	
	service = nil;
	localTicket = nil;
	query = nil;
}

- (void)testSimpleJSONQuery {
	[self prepare];
	
	GGHTTPService *service = [[GGHTTPService alloc] initWithBaseURL:nil];
	GGHTTPQuery *query = [GGHTTPQuery queryForURL:[NSURL URLWithString:@"http://:20005/test.json"]];
	query.bodyDecoder = [GGHTTPQueryBodyJSONTransformer class];
	query.expectedResultClass = [NSDictionary class];
	
	GGHTTPServiceTicket *localTicket = nil;
	localTicket = [service executeQuery:query
					  completionHandler:^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult) {
						  GHAssertNotNil(ticket, nil);
						  GHAssertNotNil(ticket.query, nil);
						  GHAssertEquals(ticket.query, query, nil);
						  GHAssertNil(ticket.fetcher, nil);
						  GHAssertTrue(ticket.used, nil);
						  
						  GHAssertNotNil(queryResult, nil);
						  GHAssertNil(queryResult.error, nil);
						  GHAssertNil(queryResult.cacheItem, nil);
						  GHAssertFalse(queryResult.cached, nil);
						  GHAssertNotNil(queryResult.data, nil);
						  GHAssertNotNil(queryResult.rawData, nil);
						  GHAssertEquals(queryResult.statusCode, (NSInteger)200, nil);
						  
						  GHAssertTrue([queryResult.data isKindOfClass:[NSDictionary class]], nil);
						  GHAssertEquals([queryResult.data count], (NSUInteger)3, nil);
						  GHAssertEqualObjects(queryResult.data[@"string"], @"A meta-markup language, used to create markup languages such as DocBook", nil);
						  GHAssertEqualObjects(queryResult.data[@"double"], @115.34, nil);
						  GHAssertEqualObjects(queryResult.data[@"int"], @115, nil);
						  						  
						  [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSimpleJSONQuery)];
					  }];
	
	[self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
	
	service = nil;
	localTicket = nil;
	query = nil;
}

@end
