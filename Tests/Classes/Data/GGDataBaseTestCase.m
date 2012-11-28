//
//  GGDataBaseTestCase.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataBaseTestCase.h"

@implementation GGDataBaseTestCase {
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSManagedObjectModel *_managedObjectModel;
	NSManagedObjectContext *_managedObjectContext;
	
	GGDataStorage *_dataStorage;
}

- (void)setUpClass {
	
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp {
	if (_dataStorage || _managedObjectContext) {
		NSPersistentStore *store = [_persistentStoreCoordinator.persistentStores lastObject];
		if (store) {
			NSURL *storeURL = store.URL;
			[_persistentStoreCoordinator removePersistentStore:store error:nil];
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		}
		
		_dataStorage = nil;
		_managedObjectContext = nil;
		_managedObjectModel = nil;
		_persistentStoreCoordinator = nil;
	}
}

- (void)tearDown {
	// Run after each test method
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

@end
