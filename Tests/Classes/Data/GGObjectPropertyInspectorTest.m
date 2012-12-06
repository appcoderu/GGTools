//
//  GGObjectPropertyInspectorTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGObjectPropertyInspectorTest.h"

#import "GGObjectPropertyInspector.h"
#import "GGObjectPropertyInspectorUnknownClass.h"

#import <CoreData/CoreData.h>

@interface GGObjectPropertyInspectorTest()

@end

@implementation GGObjectPropertyInspectorTest {
	
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

- (void)testFields {
	NSMutableDictionary *referenceProperties = [NSMutableDictionary dictionaryWithCapacity:20];
	referenceProperties[@"color"] = [UIColor class];
	referenceProperties[@"city"] = [TestCityModel class];
    referenceProperties[@"createdDate"] = [NSDate class];
    referenceProperties[@"details"] = [TestItemDetailsModel class];
    referenceProperties[@"fields"] = [GGObjectPropertyInspectorUnknownClass class];
    referenceProperties[@"identifier"] = [NSNumber class];
    referenceProperties[@"location"] = [GGObjectPropertyInspectorUnknownClass class];
    referenceProperties[@"metro"] = [NSSet class];
    referenceProperties[@"modified"] = [NSNumber class];
    referenceProperties[@"price"] = [NSNumber class];
    referenceProperties[@"rubric"] = [TestRubricModel class];
    referenceProperties[@"title"] = [NSString class];
    referenceProperties[@"updatedDate"] = [NSDate class];
	referenceProperties[@"services"] = [NSSet class];
	
	NSEntityDescription *entity = [self.dataStorage entityDescriptionWithName:@"TestItem"];
	GHAssertNotNil(entity, nil);
	
	GGObjectPropertyInspector *inspector = [GGObjectPropertyInspector inspectorForEntity:entity];
	GHAssertNotNil(inspector, nil);
	
	NSArray *propertiesList = [inspector properties];
	GHAssertNotNil(propertiesList, nil);
	GHAssertEquals([propertiesList count], [referenceProperties count], nil);
	
	[referenceProperties enumerateKeysAndObjectsUsingBlock:^(NSString *key, Class obj, BOOL *stop) {
		if ([obj isSubclassOfClass:[GGObjectPropertyInspectorUnknownClass class]]) {
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
	
	GGObjectPropertyInspector *inspector1 = [GGObjectPropertyInspector inspectorForEntity:entity1];
	GHAssertNotNil(inspector1, nil);
	
	GGObjectPropertyInspector *inspector2 = [GGObjectPropertyInspector inspectorForEntity:entity2];
	GHAssertNotNil(inspector2, nil);
	
	GHAssertEquals(inspector1, inspector2, nil);
}

@end
