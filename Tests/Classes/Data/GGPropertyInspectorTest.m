//
//  GGPropertyInspectorTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGPropertyInspectorTest.h"

#import "GGPropertyInspector.h"
#import "GGPropertyInspectorUnknownClass.h"

#import "TestItemModel.h"

#import <CoreData/CoreData.h>

@interface GGPropertyInspectorTest()

@end

@implementation GGPropertyInspectorTest {
	
}

- (void)setUpClass {

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

- (void)testManagedFields {
	NSMutableDictionary *referenceProperties = [NSMutableDictionary dictionaryWithCapacity:20];
	referenceProperties[@"color"] = [UIColor class];
	referenceProperties[@"city"] = [TestCityModel class];
    referenceProperties[@"createdDate"] = [NSDate class];
    referenceProperties[@"details"] = [TestItemDetailsModel class];
    referenceProperties[@"fields"] = [GGPropertyInspectorUnknownClass class];
    referenceProperties[@"identifier"] = [NSNumber class];
    referenceProperties[@"location"] = [GGPropertyInspectorUnknownClass class];
    referenceProperties[@"metro"] = [NSSet class];
    referenceProperties[@"modified"] = [NSNumber class];
    referenceProperties[@"price"] = [NSNumber class];
    referenceProperties[@"rubric"] = [TestRubricModel class];
    referenceProperties[@"title"] = [NSString class];
    referenceProperties[@"updatedDate"] = [NSDate class];
	referenceProperties[@"services"] = [NSSet class];
	
	NSEntityDescription *entity = [self.dataStorage entityDescriptionWithName:@"TestItem"];
	GHAssertNotNil(entity, nil);
	
	GGPropertyInspector *inspector = [GGPropertyInspector inspectorForEntity:entity];
	GHAssertNotNil(inspector, nil);
	
	NSArray *propertiesList = [inspector properties];
	GHAssertNotNil(propertiesList, nil);
	GHAssertEquals([propertiesList count], [referenceProperties count], nil);
	
	[referenceProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class obj, BOOL *stop) {
		if ([obj isSubclassOfClass:[GGPropertyInspectorUnknownClass class]]) {
			obj = nil;
		}
		
		Class propertyClass = [inspector classOfProperty:key];
		GHAssertEqualObjects(propertyClass, obj, nil);
	}];
}

- (void)testFields {
	NSMutableDictionary *referenceProperties = [NSMutableDictionary dictionaryWithCapacity:20];
	referenceProperties[@"color"] = [UIColor class];
	referenceProperties[@"city"] = [TestCityModel class];
    referenceProperties[@"createdDate"] = [NSDate class];
    referenceProperties[@"details"] = [TestItemDetailsModel class];
    referenceProperties[@"fields"] = [GGPropertyInspectorUnknownClass class];
    referenceProperties[@"identifier"] = [NSNumber class];
    referenceProperties[@"location"] = [GGPropertyInspectorUnknownClass class];
    referenceProperties[@"metro"] = [NSSet class];
    referenceProperties[@"modified"] = [NSNumber class];
    referenceProperties[@"price"] = [NSNumber class];
    referenceProperties[@"rubric"] = [TestRubricModel class];
    referenceProperties[@"title"] = [NSString class];
    referenceProperties[@"updatedDate"] = [NSDate class];
	referenceProperties[@"services"] = [NSSet class];
		
	GGPropertyInspector *inspector = [GGPropertyInspector inspectorForClass:[TestItemModel class]];
	GHAssertNotNil(inspector, nil);
	
	NSArray *propertiesList = [inspector properties];
	GHAssertNotNil(propertiesList, nil);
	GHAssertEquals([propertiesList count], [referenceProperties count], nil);
	
	[referenceProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class obj, BOOL *stop) {
		if ([obj isSubclassOfClass:[GGPropertyInspectorUnknownClass class]]) {
			obj = nil;
		}
		
		Class propertyClass = [inspector classOfProperty:key];
		GHAssertEqualObjects(propertyClass, obj, nil);
	}];
}

- (void)testCache {
	NSEntityDescription *entity1 = [self.dataStorage entityDescriptionWithName:@"TestItem"];
	GHAssertNotNil(entity1, nil);
	
	NSEntityDescription *entity2 = [self.dataStorage entityDescriptionWithName:@"TestItem"];
	GHAssertNotNil(entity2, nil);
	
	GGPropertyInspector *inspector1 = [GGPropertyInspector inspectorForEntity:entity1];
	GHAssertNotNil(inspector1, nil);
	
	GGPropertyInspector *inspector2 = [GGPropertyInspector inspectorForEntity:entity2];
	GHAssertNotNil(inspector2, nil);
	
	GHAssertEquals(inspector1, inspector2, nil);
}

@end
