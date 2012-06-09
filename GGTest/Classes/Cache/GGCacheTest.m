//
//  GGCacheTest.m
//  GG
//
//  Created by Evgeniy Shurakov on 07.06.12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGCacheTest.h"

#import "GGCache.h"
#import "GGCacheItem.h"

@interface GGCache (TestPrivate)

@end

@implementation GGCacheTest {

}

- (BOOL)shouldRunOnMainThread {
	return YES;
}

- (void)setUpClass {
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp {
	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
}

- (void)testCache {	
	GGCache *cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	[cache clear];
	
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *testMeta = nil;
	NSString *testKey = @"key";
		
	NSUInteger cacheItemsCount = 100;
	
	@autoreleasepool {
		for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
			GGCacheItem *cacheItem = [cache storeData:testData 
											 withMeta:testMeta 
											   forKey:[testKey stringByAppendingFormat:@"_%lu", i]];
			
			GHAssertNotNil(cacheItem, nil);
		}
		
		NSError *error = nil;
		BOOL result = [cache save:&error];
		
		GHAssertTrue(result, @"Save result");
		GHAssertNil(error, @"Save error");
	}
	
	[cache release];
	
	// ---

	cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
		GGCacheItem *cacheItem = [cache cachedItemForKey:[testKey stringByAppendingFormat:@"_%lu", i]];
		GHAssertNotNil(cacheItem, nil);
		GHAssertNotNil(cacheItem.data, nil);
		GHAssertEqualObjects(cacheItem.data, testData, nil);
		
		NSDictionary *meta = cacheItem.meta;
		if (meta) {
			GHAssertEquals([meta count], (NSUInteger)0, nil);
		}
	}
	
	[cache release];
}

- (void)testMetaData {
	GGCache *cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	[cache clear];
	
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *testMeta = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", nil];
	NSString *testKey = @"key";
	
	NSUInteger cacheItemsCount = 10;
	
	@autoreleasepool {
		for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
			GGCacheItem *cacheItem = [cache storeData:testData 
											 withMeta:testMeta 
											   forKey:[testKey stringByAppendingFormat:@"_%lu", i]];
			
			GHAssertNotNil(cacheItem, nil);
		}
		
		NSError *error = nil;
		BOOL result = [cache save:&error];
		
		GHAssertTrue(result, @"Save result");
		GHAssertNil(error, @"Save error");
	}
	[cache release];
	
	// ---
	
	cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
		GGCacheItem *cacheItem = [cache cachedItemForKey:[testKey stringByAppendingFormat:@"_%lu", i]];
		GHAssertNotNil(cacheItem, nil);
		GHAssertNotNil(cacheItem.data, nil);
		GHAssertEqualObjects(cacheItem.data, testData, nil);
		
		GHAssertNotNil(cacheItem.meta, nil);
		GHAssertEqualObjects(cacheItem.meta, testMeta, nil);
	}
	
	[cache release];
}

- (void)testIntegratedCache {
	// every time we alloc cache with the same folder it should be the same object
	
	GGCache *cache1 = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache1, nil);
	
	GGCache *cache2 = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache2, nil);
		
	GHAssertEquals(cache1, cache2, nil);
	
	[cache1 release];
	[cache2 release];
}

- (void)testIntegratedCacheItems {
	GGCache *cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	[cache clear];
	
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *testMeta = nil;
	NSString *testKey = @"key";
	
	GGCacheItem *cacheItem = [cache storeData:testData 
									 withMeta:testMeta 
									   forKey:testKey];
	
	GHAssertNotNil(cacheItem, nil);
	
	GGCacheItem *sameCacheItem = [cache cachedItemForKey:testKey];
	GHAssertNotNil(sameCacheItem, nil);
	GHAssertEquals(cacheItem, sameCacheItem, nil);
	
	[cache release];
}

- (void)testBasicCacheRotation {
	GGCache *cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	[cache clear];
	
	NSUInteger countLimit = 10;
	NSUInteger cacheItemsCount = 20;
	
	[cache setCountLimit:countLimit];
	
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *testMeta = nil;
	NSString *testKey = @"key";
	
	@autoreleasepool {
		for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
			GGCacheItem *cacheItem = [cache storeData:testData 
											 withMeta:testMeta 
											   forKey:[testKey stringByAppendingFormat:@"_%lu", i]];
			
			GHAssertNotNil(cacheItem, nil);
		}
	}
	
	for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
		GGCacheItem *cacheItem = [cache cachedItemForKey:[testKey stringByAppendingFormat:@"_%lu", i]];
		if (i < countLimit) {
			GHAssertNil(cacheItem, nil);
		} else {
			GHAssertNotNil(cacheItem, nil);
			GHAssertNotNil(cacheItem.data, nil);
			GHAssertEqualObjects(cacheItem.data, testData, nil);
		}
	}
	
	NSError *error = nil;
	BOOL result = [cache save:&error];
	
	GHAssertTrue(result, @"Save result");
	GHAssertNil(error, @"Save error");
	
	[cache release];
	
	// ---
	
	cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
		GGCacheItem *cacheItem = [cache cachedItemForKey:[testKey stringByAppendingFormat:@"_%lu", i]];
		if (i < countLimit) {
			GHAssertNil(cacheItem, nil);
		} else {
			GHAssertNotNil(cacheItem, nil);
			GHAssertNotNil(cacheItem.data, nil);
			GHAssertEqualObjects(cacheItem.data, testData, nil);
		}
	}
	
	[cache release];
}

- (void)testCacheRotationWithCacheItemsInUse {	
	GGCache *cache = [[GGCache alloc] initWithFolder:@"test"];
	GHAssertNotNil(cache, nil);
	
	[cache clear];
	
	NSUInteger cacheItemsCount = 10;
	NSUInteger countLimit = 10;	
	[cache setCountLimit:countLimit];
	
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *testMeta = nil;
	NSString *testKey = @"key";
	
	@autoreleasepool {
		for (NSUInteger i = 0; i < cacheItemsCount; ++i) {
			GGCacheItem *cacheItem = [cache storeData:testData 
											 withMeta:testMeta 
											   forKey:[testKey stringByAppendingFormat:@"_%lu", i]];
			
			GHAssertNotNil(cacheItem, nil);
		}
		
		NSError *error = nil;
		BOOL result = [cache save:&error];
		
		GHAssertTrue(result, @"Save result");
		GHAssertNil(error, @"Save error");
	}
	
	GGCacheItem *itemInUse = [cache cachedItemForKey:[testKey stringByAppendingFormat:@"_%lu", 0]];
	GHAssertNotNil(itemInUse, nil);
		
	@autoreleasepool {
		for (NSUInteger i = cacheItemsCount; i < 2 * cacheItemsCount; ++i) {
			GGCacheItem *cacheItem = [cache storeData:testData 
											 withMeta:testMeta 
											   forKey:[testKey stringByAppendingFormat:@"_%lu", i]];
			
			GHAssertNotNil(cacheItem, nil);
		}
	}
	
	GHAssertTrue([itemInUse exists], nil);
	
	[cache release];
}

- (void)testCacheDirectoryAbsenseDuringWork {
	// delete directory in the middle of caching
}

- (void)testPermanentCache {
	// some items may be cached permanently, so they're not deleted during cache rotation
}

- (void)testMetaWithoutDataCache {
	// it might be useful to skip data cache for some http request (like api data, which is imported in db)
}

@end
