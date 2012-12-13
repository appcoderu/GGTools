//
//  GGDataMapperTask.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/6/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapperTask.h"
#import "GGResourceConfig.h"
#import "GGDataStorage.h"
#import "GGPropertyInspector.h"
#import "GGResourcePropertyMapping.h"

#import "NSError+GGExtra.h"

#warning implement errors
#warning implement debug logging

static unsigned int debug = 0U;
enum {
	GGDataMapperDebug			= 1U << 1,
};

@implementation GGDataMapperTask {
	id _sourceData;
	GGResourceConfig *_resourceConfig;
	GGDataStorage *_dataStorage;
	
	NSMutableDictionary *_objectsCache;
}

+ (void)initialize {
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	if ([ud boolForKey:@"ru.appcode.dataMapper.debug"]) {
		debug |= GGDataMapperDebug;
	}
}

- (id)init {
	return [self initWithData:nil
			   resourceConfig:nil
				  dataStorage:nil];
}

- (id)initWithData:(id)data
	resourceConfig:(GGResourceConfig *)config
	   dataStorage:(GGDataStorage *)dataStorage {
	self = [super init];
	if (self) {
		_sourceData = data;
		_resourceConfig = config;
		_dataStorage = dataStorage;
		
		_objectsCache = [[NSMutableDictionary alloc] initWithCapacity:20];
	}
	return self;
}

- (void)execute {
	if (_resultData) {
		return;
	}
	
	_resultData = [self mapData:self.sourceData resourceConfig:self.resourceConfig];
}

#pragma mark -

- (id)mapData:(id)data resourceConfig:(GGResourceConfig *)config {
	id result = nil;
	
	if (config.importPolicy == GGResourceImportPolicyDefault) {
		config.importPolicy = (GGResourceImportPolicyAdd |
							   GGResourceImportPolicyDelete |
							   GGResourceImportPolicyPrefetch);
	}
		
	if ([data isKindOfClass:[NSArray class]]) {
		result = [self importObjects:data
					  resourceConfig:config];
		
	} else if ([data isKindOfClass:[NSDictionary class]]) {
		result = [self importObjectWithData:data
									 object:nil
							 possibleObject:nil
							 resourceConfig:config];
		
	} else if (data) {
		/*
		*error = [NSError gg_errorWithDomain:kGGDataMapperErrorDomain
										code:kGGDataMapperInvalidData
								 description:nil
							   failureReason:nil];
		 */
	}
	
	return result;
}

#pragma mark -

- (NSArray *)existingObjectsForConfig:(GGResourceConfig *)config {
	if (!config || !config.entityName) {
		return nil;
	}
	
	if (!(config.importPolicy & GGResourceImportPolicyDelete) ) {
		NSArray *objects = _objectsCache[config.entityName];
		if (objects) {
			return objects;
		}
	}
	
	NSSortDescriptor *pkSort = nil;
	if (config.primaryKey) {
		pkSort = [NSSortDescriptor sortDescriptorWithKey:config.primaryKey ascending:YES];
	}
	
	NSArray *objects = [self.dataStorage objectsWithEntityName:config.entityName
													 predicate:nil
											   sortDescriptors:(pkSort ? @[pkSort] : nil)
														 limit:0];
	
	if (!(config.importPolicy & GGResourceImportPolicyDelete)) {
		_objectsCache[config.entityName] = objects;
	}
	
	return objects;
}

- (NSArray *)importObjects:(NSArray *)objects
			resourceConfig:(GGResourceConfig *)config {
	
	if (!objects || ![objects isKindOfClass:[NSArray class]] || !config || !config.entityName) {
		return nil;
	}
		
	Class objectsClass = Nil;
	for (id objectData in objects) {
		if (!objectsClass) {
			objectsClass = [objectData class];
		} else if (![objectData isKindOfClass:objectsClass]) {
			if (debug & GGDataMapperDebug) {
				NSLog(@"Array contains objects with different classes. Skipping.");
			}
			return nil;
		}
	}
	
	/*
	if (![objectsClass isSubclassOfClass:[NSDictionary class]]) {
		if (!config.primaryKey) {
			return nil;
		}
		
		return [self.dataStorage objectsWithEntityName:config.entityName
											 predicate:[NSPredicate predicateWithFormat:@"%K IN %@", config.primaryKey, objects]
									   sortDescriptors:nil
												 limit:0];
	}
	*/
	 
	GGPropertyInspector *propertyInspector = [GGPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
	
	if (!propertyInspector) {
		if (debug & GGDataMapperDebug) {
			NSLog(@"No property inspector for entity: %@", config.entityName);
		}
		return nil;
	}
	
	Class primaryKeyClass = Nil;
	NSString *primaryKeyPath = nil;
	if (config.primaryKey) {
		primaryKeyPath = [config keyPathForProperty:config.primaryKey];
		primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
	}
	
	id existingObjects = nil;
	if ((config.importPolicy & GGResourceImportPolicyPrefetch)) {
		existingObjects = [self existingObjectsForConfig:config];
		if (existingObjects && [existingObjects count] == 0) {
			existingObjects = nil;
		}
		if (existingObjects && (config.importPolicy & GGResourceImportPolicyDelete)) {
			existingObjects = [NSMutableArray arrayWithArray:existingObjects];
		}
	}
	
	NSMutableArray *result = [[NSMutableArray alloc] init];
		
	if (![objectsClass isSubclassOfClass:[NSDictionary class]] &&
		[objectsClass instancesRespondToSelector:@selector(compare:)] &&
		existingObjects && config.primaryKey) {
		
		if ([objects count] == 0 || [existingObjects count] == 0) {
			return result;
		}

		objects = [objects sortedArrayUsingSelector:@selector(compare:)];
		
		id lastExistingPrimaryKey = [[existingObjects lastObject] valueForKey:config.primaryKey];
		
		NSUInteger index = 0;
		NSUInteger objectsCount = objects.count;
		
		while (objectsCount > 0) {
			id lastObjectPrimaryKey = objects[objectsCount - 1];
			NSComparisonResult compResult = [lastObjectPrimaryKey compare:lastExistingPrimaryKey];
			if (compResult == NSOrderedDescending) {
				--objectsCount;
			} else {
				break;
			}
		}
		
		if (objectsCount == 0) {
			return result;
		}
	
		for (id existingObject in existingObjects) {
			id existingPrimaryKeyValue = [existingObject valueForKey:config.primaryKey];
			if (!existingPrimaryKeyValue) {
				continue;
			}
			
			while (index < objectsCount) {
				id primaryKeyValue = objects[index];
				NSComparisonResult compResult = [primaryKeyValue compare:existingPrimaryKeyValue];
				if (compResult == NSOrderedSame) {
					++index;
					[result addObject:existingObject];
					break;
				} else if (compResult == NSOrderedDescending) {
					break;
				}
				
				++index;
			}
			
			if (index == objectsCount) {
				break;
			}
		}
		
		return result;
	}
	
	BOOL autoOrder = NO;
	NSUInteger order = 0;
	if (config.autoOrderProperty) {
		autoOrder = YES;
		Class orderPropertyClass = [propertyInspector classOfProperty:config.autoOrderProperty];
		if (![orderPropertyClass isSubclassOfClass:[NSNumber class]]) {
			autoOrder = NO;
		}
	}
	
	for (id _objectData in objects) {
		id primaryKeyValue = nil;
		id object = nil;
		
		// determine primary key value
		if (![objectsClass isSubclassOfClass:[NSDictionary class]]) {
			if (primaryKeyClass) {
				primaryKeyValue = [self convertValue:_objectData
											 toClass:primaryKeyClass];
			}
			
			if (!primaryKeyValue) {
				if (debug & GGDataMapperDebug) {
					NSLog(@"Can't get primary key value. %@", _objectData);
				}
				continue;
			}
			
		} else if (primaryKeyPath && primaryKeyClass) {
			primaryKeyValue = [self convertValue:[_objectData valueForKeyPath:primaryKeyPath]
										 toClass:primaryKeyClass];
			if (!primaryKeyValue) {
				if (debug & GGDataMapperDebug) {
					NSLog(@"Can't get primary key value for key path: %@. %@", primaryKeyPath, _objectData);
				}
				continue;
			}
		}
		
		if (primaryKeyValue) {
			
			if (existingObjects) {
				NSUInteger index = 0;
				for (id existingObject in existingObjects) {
					id existingPrimaryKeyValue = [existingObject valueForKey:config.primaryKey];
					if (!existingPrimaryKeyValue) {
						++index;
						continue;
					}
					
					NSComparisonResult compResult = [primaryKeyValue compare:existingPrimaryKeyValue];
					if (compResult == NSOrderedAscending) {
						break;
					} else if (compResult == NSOrderedDescending) {
						++index;
						continue;
					}
					
					object = existingObject;
					
					if ((config.importPolicy & GGResourceImportPolicyDelete)) {
						[existingObjects removeObjectAtIndex:index];
					}
					break;
				}
			}
			
			if (!object && (config.importPolicy & GGResourceImportPolicyFetchByPrimaryKey)) {
				object = [self.dataStorage objectWithField:config.primaryKey
												   equalTo:primaryKeyValue
												entityName:config.entityName];
			}
		}
		
		if (![objectsClass isSubclassOfClass:[NSDictionary class]]) {
			if (object) {
				[result addObject:object];
			}
			continue;
		}
		
		NSDictionary *objectData = _objectData;
		
		if (config.deleteObjectProperty) {
			id deleted = [objectData objectForKey:config.deleteObjectProperty];
			if (([deleted isKindOfClass:[NSNumber class]] && [deleted boolValue]) ||
				(![deleted isKindOfClass:[NSNumber class]] && deleted)) {
				
				[self.dataStorage deleteObject:object];
				continue;
			}
		}
		
		object = [self importObjectWithData:objectData
									 object:object
							 possibleObject:nil
							 resourceConfig:config];
		
		if (object) {
			if (autoOrder) {
				[object setValue:@(order++) forKey:config.autoOrderProperty];
			}
			
			[result addObject:object];
		}
	}
	
	if ((config.importPolicy & GGResourceImportPolicyDelete) &&
		existingObjects) {
		
		for (id existingObject in existingObjects) {
			[self.dataStorage deleteObject:existingObject];
		}
	}
	
	return result;
}

- (id)importObjectWithData:(id)objectData
					object:(id)object
			possibleObject:(id)possibleObject
			resourceConfig:(GGResourceConfig *)config {
	
	if (!objectData || !config) {
		return nil;
	}
	
	GGPropertyInspector *propertyInspector = nil;
	
	if (config.entityName) {
		propertyInspector = [GGPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
	} else if (!object) {
		object = [NSMutableDictionary dictionary];
	}
	
	if (!object) {
		Class primaryKeyClass = nil;
		NSString *primaryKeyPath = nil;
		if (config.primaryKey) {
			primaryKeyPath = [config keyPathForProperty:config.primaryKey];
			primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
		}
		
		id pk = nil;
		if (![objectData isKindOfClass:[NSDictionary class]]) {
			if (primaryKeyClass) {
				pk = [self convertValue:objectData
								toClass:primaryKeyClass];
			}
			
			if (!pk) {
				return object;
			}
			
		} else if (primaryKeyPath && primaryKeyClass) {
			pk = [self convertValue:[objectData valueForKeyPath:primaryKeyPath]
							toClass:primaryKeyClass];
			if (!pk) {
				return object;
			}
		}
		
		if (pk) {
			if (possibleObject) {
				id existingPk = [possibleObject valueForKey:config.primaryKey];
				if (existingPk && pk && [pk isEqual:existingPk]) {
					object = possibleObject;
				}
			}
			
			if (!object && (config.importPolicy & GGResourceImportPolicyFetchByPrimaryKey)) {
				object = [self.dataStorage objectWithField:config.primaryKey
												   equalTo:pk
												entityName:config.entityName];
			}
		}
	}
	
	if (![objectData isKindOfClass:[NSDictionary class]]) {
		return object;
	}
	
	NSDictionary *objectDict = objectData;
	
	if (!object && (config.importPolicy & GGResourceImportPolicyAdd)) {
		object = [self.dataStorage newObjectWithEntityName:config.entityName];
	}
	
	if (!object) {
		return object;
	}
	
	for (GGResourcePropertyMapping *mapping in config.mappings) {
		Class propertyClass = nil;
		
		if (propertyInspector) {
			propertyClass = [propertyInspector classOfProperty:mapping.destinationKeyPath];
			if (!propertyClass && ![propertyInspector hasProperty:mapping.destinationKeyPath]) {
				if ((debug & GGDataMapperDebug)) {
					NSLog(@"Property not found: %@ -> %@", mapping.sourceKeyPath, mapping.destinationKeyPath);
				}
				continue;
			}
		}
		
		id value = nil;
		if (mapping.destinationConfig) {
			value = [objectDict valueForKeyPath:mapping.sourceKeyPath];
			
			if (!propertyClass) {
				value = [self mapData:value
					   resourceConfig:mapping.destinationConfig];
			} else if ([propertyClass isSubclassOfClass:[NSSet class]] ||
					   [propertyClass isSubclassOfClass:[NSArray class]]) {
				if (mapping.destinationConfig.importPolicy == GGResourceImportPolicyDefault) {
					mapping.destinationConfig.importPolicy = GGResourceImportPolicyPrefetch | GGResourceImportPolicyAdd;
				}
								
				value = [self importObjects:value
							 resourceConfig:mapping.destinationConfig];
			} else {
				if (mapping.destinationConfig.importPolicy == GGResourceImportPolicyDefault) {
					mapping.destinationConfig.importPolicy = GGResourceImportPolicyFetchByPrimaryKey | GGResourceImportPolicyAdd;
				}
				
				value = [self importObjectWithData:value
											object:nil
									possibleObject:[object valueForKey:mapping.destinationKeyPath]
									resourceConfig:mapping.destinationConfig];
			}
			
		} else {
			value = [objectDict valueForKeyPath:mapping.sourceKeyPath];
		}
		
		value = [self convertValue:value
						   toClass:propertyClass];
		
		[object setValue:value forKey:mapping.destinationKeyPath];
	}
	
	return object;
}

- (id)convertValue:(id)value toClass:(Class)class {
	if (!class || !value || [value isKindOfClass:class]) {
		return value;
	}
	
	if ([class isSubclassOfClass:[NSString class]]) {
		if ([value respondsToSelector:@selector(stringValue)]) {
			return [value stringValue];
			
		} else if (![value isKindOfClass:[NSNull class]] &&
				   [value respondsToSelector:@selector(description)]) {
			
			return [value description];
		}
	} else if ([class isSubclassOfClass:[NSSet class]]) {
		if ([value isKindOfClass:[NSArray class]]) {
			return [NSSet setWithArray:value];
		}
	} else if ([class isSubclassOfClass:[NSDate class]]) {
		if ([value isKindOfClass:[NSNumber class]]) {
			return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
		}
	}
	
	return nil;
}

@end
