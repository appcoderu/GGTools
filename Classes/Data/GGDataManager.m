//
//  GGDataManager.m
//
//  Created by Evgeniy Shurakov on 7/31/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGDataManager.h"
#import "GGDataManagerTicket.h"

#import "GGDataStorage.h"
#import "GGResourceConfig.h"
#import "GGResourceAttributeMapping.h"
#import "GGObjectPropertyInspector.h"

#import "NSError+GGExtra.h"

#import <GGTools/GGTools.h>

#pragma mark -

@interface GGDataManagerInternalTicket : NSObject

+ (id)ticketWithKey:(NSString *)key;

- (id)initWithKey:(NSString *)key;

- (void)addClientTicket:(GGDataManagerTicket *)ticket;
- (void)removeClientTicket:(GGDataManagerTicket *)ticket;

- (void)enumerateClientHandlers:(void (^)(id handler))block;

@property (nonatomic, readonly, strong) NSString *key;
@property (nonatomic, copy) dispatch_block_t cancellationHandler;

@property (nonatomic, strong) NSArray *clientTickets;

@end

#pragma mark -

@implementation GGDataManager {
	NSMutableDictionary *tickets;
}

- (id)init {
	return [self initWithDataStorage:nil
						  apiService:nil];
}

- (id)initWithDataStorage:(GGDataStorage *)dataStorage
			   apiService:(GGHTTPService *)apiService {
    self = [super init];
    if (self) {
		_apiService = apiService;
		_dataStorage = dataStorage;
		
        tickets = [[NSMutableDictionary alloc] initWithCapacity:20];
    }
    return self;
}

#pragma mark - Tickets

- (void)cancelAllTasks {
	[tickets enumerateKeysAndObjectsUsingBlock:^(id key, GGDataManagerInternalTicket *internalTicket, BOOL *stop) {
		if (internalTicket.cancellationHandler) {
			(internalTicket.cancellationHandler)();
		}
	}];
	
	[tickets removeAllObjects];
}

- (void)cancelTaskWithTicket:(GGDataManagerTicket *)clientTicket {
	if (!clientTicket || !clientTicket.key) {
		return;
	}
	
	GGDataManagerInternalTicket *internalTicket = [self ticketForKey:clientTicket.key];
	if (!internalTicket) {
		return;
	}
	
	[internalTicket removeClientTicket:clientTicket];
	if ([internalTicket.clientTickets count] > 0) {
		return;
	}
	
	if (internalTicket.cancellationHandler) {
		(internalTicket.cancellationHandler)();
	}
	
	[self removeTicket:internalTicket];
}

// internal tickets

- (GGDataManagerInternalTicket *)ticketForKey:(NSString *)key {
	return [tickets objectForKey:key];
}

- (void)addTicket:(GGDataManagerInternalTicket *)ticket {
	if (!ticket || !ticket.key) {
		return;
	}
	
	[tickets setObject:ticket forKey:ticket.key];
}

- (void)removeTicket:(GGDataManagerInternalTicket *)ticket {
	if (!ticket) {
		return;
	}
	
	ticket.clientTickets = nil;
	ticket.cancellationHandler = nil;
	
	if (!ticket.key) {
		return;
	}
	
	[tickets removeObjectForKey:ticket.key];
}

#pragma mark - API Requests

- (id)executeQuery:(GGHTTPQuery *)query
	  clientTicket:(GGDataManagerTicket *)clientTicket
 completionHandler:(void (^)(GGHTTPQueryResult *result, NSArray *clientTickets))handler {
	if (!query || !clientTicket || !handler || !clientTicket.key) {
		return nil;
	}
	
	GGDataManagerInternalTicket *internalTicket = [self ticketForKey:clientTicket.key];
	if (internalTicket) {
		[internalTicket addClientTicket:clientTicket];
		return clientTicket;
	}
	
	internalTicket = [GGDataManagerInternalTicket ticketWithKey:clientTicket.key];
	if (!internalTicket) {
		return nil;
	}
	
	[internalTicket addClientTicket:clientTicket];
			
	id serviceCompletionHandler = ^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *result) {
		if (result.error) {
			
			if (result.error.domain == kGGHTTPAuthorizationErrorDomain ||
				(result.error.domain == kGGHTTPFetcherStatusDomain && result.error.code == kGGHTTPFetcherStatusUnauthorized)) {
				
#warning unauthorized
			}
			
			if (result.error.domain == kGGHTTPFetcherStatusDomain) {
				if ([result.data isKindOfClass:[NSDictionary class]]) {
					id error = [result.data objectForKey:@"error"];
					NSString *errorStr = nil;
					if ([error isKindOfClass:[NSString class]]) {
						errorStr = error;
					} else if ([error isKindOfClass:[NSArray class]]) {
						errorStr = [error componentsJoinedByString:@"\n"];
					} else if ([error isKindOfClass:[NSDictionary class]]) {
						NSMutableArray *errorComponents = [[NSMutableArray alloc] initWithCapacity:10];
						[error enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
							[errorComponents addObject:[NSString stringWithFormat:@"%@: %@", key, obj]];
						}];
						errorStr = [errorComponents componentsJoinedByString:@"\n"];
					}
					
					if (errorStr) {
						result.error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
														   code:0
													description:NSLocalizedString(@"Error", nil)
												  failureReason:errorStr
												underlyingError:result.error];
					}
				}
			}
		}
		handler(result, internalTicket.clientTickets);
		[self removeTicket:internalTicket];
	};
		
	GGHTTPServiceTicket *apiTicket = [self.apiService executeQuery:query
												 completionHandler:serviceCompletionHandler];
	
	if (!apiTicket) {
		internalTicket.clientTickets = nil;
		internalTicket = nil;
		
		return nil;
	}
	
	[self addTicket:internalTicket];
	
	__weak GGHTTPService *weakApiService = self.apiService;
	
	internalTicket.cancellationHandler = ^{
		GGHTTPService *localApiService = weakApiService;
		if (!localApiService) {
			return;
		}
		[localApiService cancelQueryWithTicket:apiTicket];
	};
	
	return clientTicket;
}

#pragma mark -

- (id)loadObjectsWithQuery:(GGHTTPQuery *)query
			resourceConfig:(GGResourceConfig *)config
		 completionHandler:(void (^)(NSArray *objects, NSError *error))handler {
	
	NSString *ticketKey = [NSString stringWithFormat:@"%ui", [query hash]];

	GGDataManagerTicket *clientTicket = [GGDataManagerTicket ticketWithKey:ticketKey
														 completionHandler:handler];
		
	return [self executeQuery:query
				 clientTicket:clientTicket
			completionHandler:^(GGHTTPQueryResult *result, NSArray *clientTickets) {
				NSArray *objects = nil;
				if (!result.error && !result.cached) {
					objects = [self importObjects:result.data resourceConfig:config];
				}

				for (GGDataManagerTicket *ticket in clientTickets) {
					if (ticket.completionHandler) {
						void (^localHandler)(NSArray *objects, NSError *error) = ticket.completionHandler;
						localHandler(objects, result.error);
					}
				}
			}];
}

#pragma mark -

- (GGHTTPQuery *)queryWithRelativePath:(NSString *)methodName {
	GGHTTPQuery *query = [GGHTTPQuery queryWithRelativePath:methodName];
	[query setHTTPHeader:@"application/json" forKey:@"Accept"];
	return query;
}

- (GGHTTPQuery *)queryForResourceKey:(NSString *)resourceKey {
	return nil;
}

#pragma mark -

//- (id)processResponse:(id)object resourceConfig:(GGResourceConfig *)config {
//
//}

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

- (id)importObjectWithData:(id)_objectData
					object:(id)object
			possibleObject:(id)possibleObject
			resourceConfig:(GGResourceConfig *)config {
	
	if (!_objectData || !config) {
		return nil;
	}
	
	GGObjectPropertyInspector *propertyInspector = [GGObjectPropertyInspector inspectorForEntity:[self.dataStorage entityDescriptionWithName:config.entityName]];
	
	
	if (!object) {
		Class primaryKeyClass = nil;
		NSString *primaryKeyPath = nil;
		if (config.primaryKey) {
			primaryKeyPath = [config keyPathForAttribute:config.primaryKey];
			primaryKeyClass = [propertyInspector classOfProperty:config.primaryKey];
		}
				
		id pk = nil;
		if (![_objectData isKindOfClass:[NSDictionary class]]) {
			if (!primaryKeyClass) {
				return object;
			}
			
			pk = [self convertValue:_objectData
							toClass:primaryKeyClass];
			if (!pk) {
				return object;
			}
			
		} else if (primaryKeyPath && primaryKeyClass) {
			pk = [self convertValue:[_objectData valueForKeyPath:primaryKeyPath]
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
	
	if (![_objectData isKindOfClass:[NSDictionary class]]) {
		return object;
	}
	NSDictionary *objectData = _objectData;
		
	if (!object && (config.importPolicy & GGResourceImportPolicyAdd)) {
		object = [self.dataStorage newObjectWithEntityName:config.entityName];
	}
	
	if (!object) {
		return object;
	}

	for (GGResourceAttributeMapping *mapping in config.attributeMappings) {
		Class propertyClass = [propertyInspector classOfProperty:mapping.destinationKeyPath];
		if (!propertyClass) {
#warning error
			NSLog(@"Property not found: %@", mapping.destinationKeyPath);
			continue;
		}
		
		id value = nil;
		if (mapping.destinationConfig) {
			mapping.destinationConfig.importPolicy = GGResourceImportPolicyFetchByPK |
			GGResourceImportPolicyAdd;
			
			value = [objectData valueForKeyPath:mapping.sourceKeyPath];
			
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
			value = [objectData valueForKeyPath:mapping.sourceKeyPath];
		}
		
		value = [self convertValue:value
						   toClass:propertyClass];
		
		[object setValue:value forKey:mapping.destinationKeyPath];
	}
	
	return object;
}

- (id)convertValue:(id)value toClass:(Class)class {
	if (!value) {
		return value;
	}
	
	if (!class) {
		return nil;
	}
	
	if ([value isKindOfClass:class]) {
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

@implementation GGDataManagerInternalTicket {
	NSMutableArray *clientTickets;
}

@synthesize key, cancellationHandler;
@synthesize clientTickets;

+ (id)ticketWithKey:(NSString *)key {
	return [[[self class] alloc] initWithKey:key];
}

- (id)initWithKey:(NSString *)aKey {
	self = [super init];
	if (self) {
		if (!aKey || [aKey length] == 0) {
			self = nil;
			return self;
		}
		
		clientTickets = [[NSMutableArray alloc] initWithCapacity:1];
		key = aKey;
	}
	
	return self;
}

- (void)addClientTicket:(GGDataManagerTicket *)ticket {
	[clientTickets addObject:ticket];
}

- (void)removeClientTicket:(GGDataManagerTicket *)ticket {
	[clientTickets removeObject:ticket];
}

- (void)enumerateClientHandlers:(void (^)(id handler))block {
	if (!block) {
		return;
	}
	for (GGDataManagerTicket *ticket in clientTickets) {
		block(ticket.completionHandler);
	}
}

@end

