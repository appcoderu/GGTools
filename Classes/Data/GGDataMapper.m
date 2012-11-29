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
#import "GGResourceAttributeMapping.h"

#import "NSError+GGExtra.h"

@implementation GGDataMapper

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
		result = [self importObjects:data resourceConfig:config];
	} else if ([data isKindOfClass:[NSDictionary class]]) {
		result = [self importObjectWithData:data resourceConfig:config];
	}
	
	return result;
}

- (NSArray *)importObjects:(NSArray *)objects resourceConfig:(GGResourceConfig *)config {
	return [self importObjects:objects existingObjects:nil resourceConfig:config];
}

- (NSArray *)importObjects:(NSArray *)objects
		   existingObjects:(id)existingObjects
			resourceConfig:(GGResourceConfig *)config {
	
	if (!objects || ![objects isKindOfClass:[NSArray class]] || !config) {
		return nil;
	}
	
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	if ((config.importPolicy & GGResourceImportPolicyPrefetch) && !existingObjects) {
		existingObjects = [self.dataStorage objectsWithEntityName:config.entityName
														predicate:nil
												  sortDescriptors:nil
															limit:0];
	}
	
	if (existingObjects &&
		![existingObjects isKindOfClass:[NSSet class]] &&
		![existingObjects isKindOfClass:[NSArray class]]) {
		
		existingObjects = nil;
	}
	
	GGObjectPropertyInspector *propertyInspector = [GGObjectPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
	
	Class primaryKeyClass = nil;
	NSString *primaryKeyPath = nil;
	if (config.primaryKey) {
		primaryKeyPath = [config keyPathForAttribute:config.primaryKey];
		primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
	}
	
	for (id _objectData in objects) {
		id pk = nil;
		id object = nil;
		
		if (![_objectData isKindOfClass:[NSDictionary class]]) {
			if (!primaryKeyClass) {
				continue;
			}
			
			pk = [self convertValue:_objectData
							toClass:primaryKeyClass];
			if (!pk) {
				continue;
			}
			
		} else if (primaryKeyPath && primaryKeyClass) {
			pk = [self convertValue:[_objectData valueForKeyPath:primaryKeyPath]
							toClass:primaryKeyClass];
			if (!pk) {
				continue;
			}
		}
		
		if (pk) {
			if (existingObjects) {
				NSUInteger index = 0;
				for (id existingObject in existingObjects) {
					id existingPk = [existingObject valueForKey:config.primaryKey];
					if (existingPk && pk && [pk isEqual:existingPk]) {
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
			
#warning 123
			if (!object && (config.importPolicy & GGResourceImportPolicyFetchByPK) &&
				(!existingObjects || ![_objectData isKindOfClass:[NSDictionary class]])) {
				
				object = [self.dataStorage objectWithField:config.primaryKey
												   equalTo:pk
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
		
		if (config.importPolicy == GGResourceImportPolicyIncremental) {
#warning extract field name
			id deleted = [self convertValue:[objectData objectForKey:@"deleted"]
									toClass:[NSNumber class]];
			if (deleted && [deleted boolValue]) {
				[self.dataStorage deleteObject:object];
				continue;
			}
		}
		
		object = [self importObjectWithData:objectData
									 object:object
							 possibleObject:nil
							 resourceConfig:config];
		
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

- (id)importObjectWithData:(id)objectData resourceConfig:(GGResourceConfig *)config {
	return [self importObjectWithData:objectData
							   object:nil
					   possibleObject:nil
					   resourceConfig:config];
}

- (id)importObjectWithData:(id)objectData
					object:(id)object
			possibleObject:(id)possibleObject
			resourceConfig:(GGResourceConfig *)config {
	
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
			primaryKeyPath = [config keyPathForAttribute:config.primaryKey];
			primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
		}
		
		id pk = nil;
		if (![objectData isKindOfClass:[NSDictionary class]]) {
			if (!primaryKeyClass) {
				return object;
			}
			
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
			
			if (!object && (config.importPolicy & GGResourceImportPolicyFetchByPK)) {
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
	
	for (GGResourceAttributeMapping *mapping in config.attributeMappings) {
		Class propertyClass = nil;
		
		if (propertyInspector) {
			[propertyInspector classOfProperty:mapping.destinationKeyPath];
			if (!propertyClass && ![propertyInspector hasProperty:mapping.destinationKeyPath]) {
#warning error
				NSLog(@"Property not found: %@", mapping.destinationKeyPath);
				continue;
			}
		}
		
		id value = nil;
		if (mapping.destinationConfig) {
			mapping.destinationConfig.importPolicy = GGResourceImportPolicyFetchByPK |
			GGResourceImportPolicyAdd;
			
			value = [objectDict valueForKeyPath:mapping.sourceKeyPath];
			
			if ([propertyClass isSubclassOfClass:[NSSet class]] ||
				[propertyClass isSubclassOfClass:[NSArray class]]) {
				
				value = [self importObjects:value
							existingObjects:[object valueForKey:mapping.destinationKeyPath]
							 resourceConfig:mapping.destinationConfig];
			} else {
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
	}
	
	return nil;
}

@end
