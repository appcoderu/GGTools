//
//  GGObjectPropertyInspector.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//
//	Most of the code of this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGObjectPropertyInspector.h"
#import "GGObjectPropertyInspectorUnknownClass.h"

#import <CoreData/CoreData.h>
#import <objc/message.h>

static NSMutableDictionary *propertyInspectorCache = nil;

@implementation GGObjectPropertyInspector {
	NSEntityDescription *_entity;
	NSMutableDictionary *_properties;
}

+ (id)inspectorForEntity:(NSEntityDescription *)entity {
	if (!entity) {
		return nil;
	}
	
	if (!propertyInspectorCache) {
		propertyInspectorCache = [[NSMutableDictionary alloc] initWithCapacity:20];
	}
	
	id obj = propertyInspectorCache[entity.name];
	if (!obj) {
		obj = [[self alloc] initWithEntity:entity];
		propertyInspectorCache[entity.name] = obj;
	}
	return obj;
}

+ (NSString *)propertyTypeFromAttributeString:(NSString *)attributeString {
    NSString *type = [NSString string];
    NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];
	
    // we are not dealing with an object
    if ([typeScanner isAtEnd]) {
        return @"NULL";
    }
    [typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
    // this gets the actual object type
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
    return type;
}

#pragma mark -

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
	
	NSDictionary *attributesByName = [_entity attributesByName];
	NSDictionary *relationshipsByName = [_entity relationshipsByName];
	
	_properties = [[NSMutableDictionary alloc] initWithCapacity:(attributesByName.count + relationshipsByName.count)];
	
	[attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *attributeDescription, BOOL *stop) {
		
		if ([attributeDescription attributeValueClassName]) {
            [_properties setObject:NSClassFromString([attributeDescription attributeValueClassName])
							forKey:name];
			
        } else if ([attributeDescription attributeType] == NSTransformableAttributeType &&
                   ![name isEqualToString:@"_mapkit_hasPanoramaID"]) {

            const char *propertyName = [name cStringUsingEncoding:NSUTF8StringEncoding];
            Class managedObjectClass = NSClassFromString([_entity managedObjectClassName]);
			
            objc_property_t prop = class_getProperty(managedObjectClass, propertyName);
			if (!prop) {
				return;
			}
			
            NSString *attributeString = [NSString stringWithCString:property_getAttributes(prop)
														   encoding:NSUTF8StringEncoding];
						
			Class aClass = NSClassFromString([[self class] propertyTypeFromAttributeString:attributeString]);
            if (!aClass) {
				aClass = [GGObjectPropertyInspectorUnknownClass class];
            }
			
			[_properties setObject:aClass forKey:name];
        }
	}];
	
	[relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSRelationshipDescription *relationshipDescription, BOOL *stop) {
		
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
	Class class = [_properties objectForKey:propertyName];
	if ([class isSubclassOfClass:[GGObjectPropertyInspectorUnknownClass class]]) {
		class = nil;
	}
	return class;
}

- (NSArray *)properties {
	return [_properties allKeys];
}

@end
