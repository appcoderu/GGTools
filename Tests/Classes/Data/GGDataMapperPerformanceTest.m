//
//  GGDataMapperPerformanceTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/6/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapperPerformanceTest.h"

#import "GGResourceConfig.h"
#import "GGDataMapper.h"

@implementation GGDataMapperPerformanceTest

/*
- (void)testPerformance {
	GGDataMapper *mapper = [[GGDataMapper alloc] initWithDataStorage:self.dataStorage];
	GHAssertNotNil(mapper, nil);
	
	[mapper mapData:[self dataForResource:@"services"]
	 resourceConfig:[self servicesConfig]
			  error:nil];
	
	NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
	
	NSError *error = nil;
	NSArray *items = [mapper mapData:[self dataForResource:@"items-big"]
					  resourceConfig:[self itemsConfig]
							   error:&error];
	
	NSLog(@"%f", [NSDate timeIntervalSinceReferenceDate] - t1);
		
	t1 = [NSDate timeIntervalSinceReferenceDate];
	
	error = nil;
	items = [mapper mapData:[self dataForResource:@"items-big"]
			 resourceConfig:[self itemsConfig]
					  error:&error];
	
	NSLog(@"%f", [NSDate timeIntervalSinceReferenceDate] - t1);
}
*/

@end
