//
//  GGManagedObjectPropertyInspector.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/13/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//
//	Most of the code for this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGManagedObjectPropertyInspector.h"
#import "GGPropertyInspector+Protected.h"

#import "GGPropertyInspectorUnknownClass.h"

#import <CoreData/CoreData.h>
#import <objc/message.h>

@implementation GGManagedObjectPropertyInspector {
	NSEntityDescription *_entity;
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
	NSDictionary *attributesByName = [_entity attributesByName];
	NSDictionary *relationshipsByName = [_entity relationshipsByName];
		
	[attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attributeDescription, BOOL *stop) {
		
		if ([attributeDescription attributeValueClassName]) {
			[self setClass:NSClassFromString([attributeDescription attributeValueClassName])
			   forProperty:name];
			
        } else if ([attributeDescription attributeType] == NSTransformableAttributeType &&
                   ![name isEqualToString:@"_mapkit_hasPanoramaID"]) {
			
            const char *propertyName = [name cStringUsingEncoding:NSUTF8StringEncoding];
            Class managedObjectClass = NSClassFromString([_entity managedObjectClassName]);
			
            objc_property_t prop = class_getProperty(managedObjectClass, propertyName);
			if (!prop) {
				return;
			}
						
			Class aClass = [[self class] classFromPropertyAttributeString:property_getAttributes(prop)];
            if (!aClass) {
				aClass = [GGPropertyInspectorUnknownClass class];
            }
			
			[self setClass:aClass forProperty:name];
        }
	}];
	
	[relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
		
		if ([relationshipDescription isToMany]) {
			[self setClass:[NSSet class] forProperty:name];
        } else {
            NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
            Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);
			[self setClass:destinationClass forProperty:name];
        }
	}];
}

@end
