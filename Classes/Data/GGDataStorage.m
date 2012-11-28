//
//  GGDataStorage.m
//
//  Created by Evgeniy Shurakov on 27.02.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGDataStorage.h"

#import <CoreData/CoreData.h>

static const NSTimeInterval kSaveDelayInterval = 1.0;

@interface GGDataStorage ()

@end

@implementation GGDataStorage {

}

- (id)init {
	return [self initWithStorage:nil];
}

- (id)initWithStorage:(NSManagedObjectContext *)_managedObjectContext {
	
	self = [super init];
	
	if (self) {
		if (!_managedObjectContext) {
			self = nil;
			return self;
		}

		_storage = _managedObjectContext;
	}
	
	return self;
}

- (void)dealloc {
	
}

#pragma mark -

- (void)save {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(save) object:nil];
	NSError *error = nil;
	
	[_storage save:&error];
		
	if (error) {
		NSLog(@"%@", error);
	}
}

- (void)setNeedsSave {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(save) object:nil];
	[self performSelector:@selector(save) withObject:nil afterDelay:kSaveDelayInterval];
}

#pragma mark - Meta

- (NSDictionary *)meta {
	NSPersistentStoreCoordinator *coordinator = _storage.persistentStoreCoordinator;
	if (!coordinator.persistentStores || [coordinator.persistentStores count] == 0) {
		return nil;
	}
	return [coordinator metadataForPersistentStore:[coordinator.persistentStores objectAtIndex:0]];
}

- (void)setMeta:(NSDictionary *)meta {
	NSPersistentStoreCoordinator *coordinator = _storage.persistentStoreCoordinator;
	if (!coordinator.persistentStores || [coordinator.persistentStores count] == 0) {
		return;
	}
	[coordinator setMetadata:meta
		  forPersistentStore:[coordinator.persistentStores objectAtIndex:0]];
}

- (id)metaForKey:(NSString *)key {
	return [[self meta] objectForKey:key];
}

- (void)setMeta:(id)value forKey:(NSString *)key {
	if (!key) {
		return;
	}
	
	NSMutableDictionary *meta = [[self meta] mutableCopy];
	
	if (value) {
        [meta setObject:value forKey:key];
	} else {
		[meta removeObjectForKey:key];
	}
	
	[self setMeta:meta];
	
	[self save];
}

#pragma mark -

- (NSEntityDescription *)entityDescriptionWithName:(NSString *)entityName {
	return [NSEntityDescription entityForName:entityName
					   inManagedObjectContext:_storage];
}

- (id)newObjectWithEntityName:(NSString *)entityName {
	NSEntityDescription *entity = [self entityDescriptionWithName:entityName];
	if (!entity) {
		return nil;
	}
	
	return [[NSManagedObject alloc] initWithEntity:entity
					insertIntoManagedObjectContext:_storage];
}

- (void)deleteObjectsWithEntityName:(NSString *)entityName {
	[self deleteObjectsWithEntityName:entityName
							predicate:nil];
}

- (void)deleteObjectsWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate {
	NSEntityDescription *entity = [self entityDescriptionWithName:entityName];
	
	if (!entity) {
		return;
	}
	
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity:entity];
	[fr setIncludesPropertyValues:NO];
	if (predicate) {
		[fr setPredicate:predicate];
	}
	
	NSArray *objects = [_storage executeFetchRequest:fr error:nil];
	for (NSManagedObject *object in objects) {
		[self deleteObject:object];
	}
	
	[self setNeedsSave];
}

- (void)deleteObject:(NSManagedObject *)object {
	if (!object) {
		return;
	}
	
	[_storage deleteObject:object];
}

- (id)objectWithIdentifier:(id)identifier entityName:(NSString *)entityName {
	NSEntityDescription *entity = [self entityDescriptionWithName:entityName];
	
	if (!entity) {
		return nil;
	}
	
	static NSPredicate *fetchPredicate = nil;
	if (!identifier) {
		return nil;
	}
	
	if (!fetchPredicate) {
		fetchPredicate = [NSPredicate predicateWithFormat:@"identifier = $identifier"];
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	NSDictionary *variables = @{@"identifier": identifier};
	
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:[fetchPredicate predicateWithSubstitutionVariables:variables]];
	[fetchRequest setIncludesSubentities:NO];
	[fetchRequest setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *objects = [_storage executeFetchRequest:fetchRequest error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	return [objects lastObject];
}

- (id)objectWithField:(NSString *)fieldName equalTo:(id)fieldValue entityName:(NSString *)entityName {
	NSEntityDescription *entity = [self entityDescriptionWithName:entityName];
	if (!entity) {
		return nil;
	}
	
	if (!fieldName || !fieldValue) {
		return nil;
	}
	
	NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:[fieldName stringByAppendingString:@" = %@"], fieldValue];
		
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:fetchPredicate];
	[fetchRequest setIncludesSubentities:NO];
	[fetchRequest setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *objects = [_storage executeFetchRequest:fetchRequest error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	return [objects lastObject];	
}

- (NSArray *)objectsWithEntityName:(NSString *)entityName
						 predicate:(NSPredicate *)predicate
				   sortDescriptors:(NSArray *)sortDescriptors
							 limit:(NSUInteger)limit {
	NSEntityDescription *entity = [self entityDescriptionWithName:entityName];
	
	if (!entity) {
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	[fetchRequest setEntity:entity];
	
	if (predicate) {
		[fetchRequest setPredicate:predicate];
	}
	
	if (sortDescriptors) {
		[fetchRequest setSortDescriptors:sortDescriptors];
	}
	
	if (limit > 0) {
		[fetchRequest setFetchLimit:limit];
	}
	
	NSError *error = nil;
	NSArray *result = [_storage executeFetchRequest:fetchRequest error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
	
	if (![result isKindOfClass:[NSArray class]]) {
		result = @[];
	}
	
	return result;
}

@end
