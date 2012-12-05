//
//  GGDataMapper.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/29/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapper.h"

#import "GGDataStorage.h"
#import "GGResourceConfig.h"
#import "GGObjectPropertyInspector.h"
#import "GGResourcePropertyMapping.h"

#import "NSError+GGExtra.h"

#warning implement errors
#warning implement debug logging

static unsigned int debug = 0U;
enum {
	GGDataMapperDebug			= 1U << 1,
};

@implementation GGDataMapper

+ (void)initialize {
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	if ([ud boolForKey:@"ru.appcode.dataMapper.debug"]) {
		debug |= GGDataMapperDebug;
	}
}

- (id)init {
	return [self initWithDataStorage:nil];
}

- (id)initWithDataStorage:(GGDataStorage *)dataStorage {
	self = [super init];
	if (self) {
		_dataStorage = dataStorage;
	}
	return self;
}

- (id)mapData:(id)data resourceConfig:(GGResourceConfig *)config error:(NSError **)error {
	id result = nil;
		
	if ([data isKindOfClass:[NSArray class]]) {
		result = [self importObjects:data
					 existingObjects:nil
					  resourceConfig:config
							   error:error];
		
	} else if ([data isKindOfClass:[NSDictionary class]]) {
		result = [self importObjectWithData:data
									 object:nil
							 possibleObject:nil 
							 resourceConfig:config
									  error:error];
		
	} else if (data && error) {
		*error = [NSError gg_errorWithDomain:kGGDataMapperErrorDomain
										code:kGGDataMapperInvalidData
								 description:nil
							   failureReason:nil];
	}
		
	return result;
}

- (NSArray *)importObjects:(NSArray *)objects
		   existingObjects:(id)existingObjects
			resourceConfig:(GGResourceConfig *)config
					 error:(NSError **)error {
	
	if (!objects || ![objects isKindOfClass:[NSArray class]] || !config) {
		return nil;
	}
		
	if ((config.importPolicy & GGResourceImportPolicyPrefetch) && !existingObjects) {
		existingObjects = [self.dataStorage objectsWithEntityName:config.entityName
														predicate:nil
												  sortDescriptors:nil
															limit:0];
	}
	
	if (existingObjects) {
		if ([existingObjects isKindOfClass:[NSSet class]]) {
			if (![existingObjects respondsToSelector:@selector(removeObject:)]) {
				existingObjects = [NSMutableSet setWithSet:existingObjects];
			}
		} else if ([existingObjects isKindOfClass:[NSArray class]]) {
			if (![existingObjects respondsToSelector:@selector(removeObjectAtIndex:)]) {
				existingObjects = [NSMutableArray arrayWithArray:existingObjects];
			}
		} else {
			existingObjects = nil;
		}
	}
	
	GGObjectPropertyInspector *propertyInspector = [GGObjectPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
	
	if (!propertyInspector) {
		if (debug & GGDataMapperDebug) {
			NSLog(@"No property inspector for entity: %@", config.entityName);
		}
		return nil;
	}
	
	Class primaryKeyClass = nil;
	NSString *primaryKeyPath = nil;
	if (config.primaryKey) {
		primaryKeyPath = [config keyPathForProperty:config.primaryKey];
		primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
	}
	
	Class classToTest = nil;
	for (id objectData in objects) {
		if (!classToTest) {
			classToTest = [objectData class];
		} else if (![objectData isKindOfClass:classToTest]) {
			if (debug & GGDataMapperDebug) {
				NSLog(@"Array contains objects with different classes. Skipping.");
			}
			
			if (error) {
				*error = [NSError gg_errorWithDomain:kGGDataMapperErrorDomain
												code:kGGDataMapperInvalidData
										 description:nil
									   failureReason:nil];
			}
			return nil;
		}
	}
		
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	for (id _objectData in objects) {
		id primaryKeyValue = nil;
		id object = nil;
		
		// determine primary key value
		if (![_objectData isKindOfClass:[NSDictionary class]]) {
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
					if (existingPrimaryKeyValue && primaryKeyValue && [primaryKeyValue isEqual:existingPrimaryKeyValue]) {
						object = existingObject;
						
						if ([existingObjects isKindOfClass:[NSSet class]]) {
							[existingObjects removeObject:existingObject];
						} else {
							[existingObjects removeObjectAtIndex:index];
						}
						break;
					}
					++index;
				}
			}
			
			if (!object && (config.importPolicy & GGResourceImportPolicyFetchByPrimaryKey)) {
				object = [self.dataStorage objectWithField:config.primaryKey
												   equalTo:primaryKeyValue
												entityName:config.entityName];
			}
		}
		
		if (![_objectData isKindOfClass:[NSDictionary class]]) {
			if (object) {
				[result addObject:object];
			}
			continue;
		}
		
		NSDictionary *objectData = _objectData;
		
		if (config.propertyToDeleteObject) {
			id deleted = [objectData objectForKey:config.propertyToDeleteObject];
			if (([deleted isKindOfClass:[NSNumber class]] && [deleted boolValue]) ||
				(![deleted isKindOfClass:[NSNumber class]] && deleted)) {
				
				[self.dataStorage deleteObject:object];
				continue;
			}
		}
		
		object = [self importObjectWithData:objectData
									 object:object
							 possibleObject:nil
							 resourceConfig:config
									  error:nil];
		
		if (object) {
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
			resourceConfig:(GGResourceConfig *)config
					 error:(NSError **)error {
	
	if (!objectData || !config) {
		return nil;
	}
	
	GGObjectPropertyInspector *propertyInspector = nil;
	
	if (config.entityName) {
		propertyInspector = [GGObjectPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
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
			pk = [self convertValue:objectData
							toClass:primaryKeyClass];
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
					   resourceConfig:mapping.destinationConfig
								error:nil];
			} else if ([propertyClass isSubclassOfClass:[NSSet class]] ||
					   [propertyClass isSubclassOfClass:[NSArray class]]) {
				mapping.destinationConfig.importPolicy = GGResourceImportPolicyFetchByPrimaryKey | GGResourceImportPolicyAdd;
				
				value = [self importObjects:value
							existingObjects:[object valueForKey:mapping.destinationKeyPath]
							 resourceConfig:mapping.destinationConfig
									  error:error];
			} else {
				mapping.destinationConfig.importPolicy = GGResourceImportPolicyFetchByPrimaryKey | GGResourceImportPolicyAdd;
				
				value = [self importObjectWithData:value
											object:nil
									possibleObject:[object valueForKey:mapping.destinationKeyPath]
									resourceConfig:mapping.destinationConfig
											 error:error];
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
