//
//  GGObjectPropertyInspectorTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGObjectPropertyInspectorTest.h"

#import "GGDataStorage.h"
#import "GGObjectPropertyInspector.h"
#import "GGObjectPropertyInspectorUnknownClass.h"

#import "TestCityModel.h"
#import "TestItemDetailsModel.h"
#import "TestRubricModel.h"

#import <CoreData/CoreData.h>

@interface GGObjectPropertyInspectorTest()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly, strong, nonatomic) GGDataStorage *dataStorage;

@end

@implementation GGObjectPropertyInspectorTest {
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectModel *_managedObjectModel;
	NSManagedObjectContext *_managedObjectContext;
	
	GGDataStorage *_dataStorage;
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TestModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSString *)dbName {
	return @"Tests.sqlite";
}

- (NSURL *)storeURL {
	return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[self dbName]];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self storeURL];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption: @(YES), NSInferMappingModelAutomaticallyOption: @(YES)} error:&error]) {
        
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		
		NSURL *cacheDirURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
																	 inDomains:NSUserDomainMask] lastObject];
		NSString *cacheDirPath = [cacheDirURL path];
		
		NSDirectoryEnumerator* en = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirPath];
		NSString *file = nil;
		while (file = [en nextObject]) {
			[[NSFileManager defaultManager] removeItemAtPath:[cacheDirPath stringByAppendingPathComponent:file] error:nil];
		}
		
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
			
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
    }
    
    return _persistentStoreCoordinator;
}

- (GGDataStorage *)dataStorage {
	if (_dataStorage != nil) {
		return _dataStorage;
	}
	_dataStorage = [[GGDataStorage alloc] initWithStorage:[self managedObjectContext]];
	return _dataStorage;
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
