//
//  GGDataStorage.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 27.02.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;
@class NSEntityDescription;
@class NSManagedObject;

@interface GGDataStorage : NSObject 

@property (nonatomic, readonly, strong) NSManagedObjectContext *storage;
- (id)initWithStorage:(NSManagedObjectContext *)managedObjectContext;

#pragma mark -

- (void)save;
- (void)setNeedsSave;

#pragma mark -

- (id)metaForKey:(NSString *)key;
- (void)setMeta:(id)value forKey:(NSString *)key;

#pragma mark -

- (NSEntityDescription *)entityDescriptionWithName:(NSString *)entityName;

- (id)newObjectWithEntityName:(NSString *)entityName;
- (id)objectWithIdentifier:(id)identifier entityName:(NSString *)entityName;

- (id)objectWithField:(NSString *)fieldName equalTo:(id)fieldValue entityName:(NSString *)entityName;

- (void)deleteObject:(NSManagedObject *)object;

- (NSArray *)objectsWithEntityName:(NSString *)entityName
						 predicate:(NSPredicate *)predicate
				   sortDescriptors:(NSArray *)sortDescriptors
							 limit:(NSUInteger)limit;

@end
