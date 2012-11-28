//
//  GGObjectPropertyInspector.m
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//
//	Code is partially taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGObjectPropertyInspector.h"
#import <CoreData/CoreData.h>

#warning cache

@implementation GGObjectPropertyInspector {
	NSEntityDescription *_entity;
	NSMutableDictionary *_properties;
}

+ (id)inspectorForEntity:(NSEntityDescription *)entity {
	return [[self alloc] initWithEntity:entity];
}

- (id)init {
	return [self initWithEntity:nil];
}

- (id)initWithEntity:(NSEntityDescription *)entity {
	self = [super init];
	if (self) {
		_entity = entity;
		if (!_entity) {
			return nil;
		}
		
		[self inspect];
	}
	return self;
}

- (void)inspect {
	if (_properties) {
		return;
	}
	_properties = [[NSMutableDictionary alloc] initWithCapacity:50];
	
	[[_entity attributesByName] enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attributeDescription, BOOL *stop) {
		
		if ([attributeDescription attributeValueClassName]) {
            [_properties setValue:NSClassFromString([attributeDescription attributeValueClassName])
						   forKey:name];
			
        } else {
			NSLog(@"%@", attributeDescription);
		}
	}];
	
	[[_entity relationshipsByName] enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
		
		if ([relationshipDescription isToMany]) {
            [_properties setValue:[NSSet class] forKey:name];
        } else {
            NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
            Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);
            [_properties setValue:destinationClass forKey:name];
        }
	}];
}

- (BOOL)hasProperty:(NSString *)property {
	return ([_properties objectForKey:property] != nil);
}

- (Class)classOfProperty:(NSString *)propertyName {
	return [_properties objectForKey:propertyName];
}

@end
