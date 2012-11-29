//
//  GGDataStorageTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataStorageTest.h"

@implementation GGDataStorageTest

- (void)testMeta {
	GHAssertNotNil(self.dataStorage, nil);
	[self.dataStorage setMeta:@"testValue" forKey:@"test"];
	GHAssertEqualObjects(@"testValue", [self.dataStorage metaForKey:@"test"], nil);
	
	[self.dataStorage save];
	
	self.managedObjectContext = nil;
	self.managedObjectModel = nil;
	self.persistentStoreCoordinator = nil;
	self.dataStorage = nil;
	
	GHAssertEqualObjects(@"testValue", [self.dataStorage metaForKey:@"test"], nil);
}

@end
