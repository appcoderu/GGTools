//
//  GGPropertyInspector.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//
//	Most of the code for this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGPropertyInspector.h"
#import "GGPropertyInspectorUnknownClass.h"

#import "GGObjectPropertyInspector.h"
#import "GGManagedObjectPropertyInspector.h"

#import <CoreData/CoreData.h>
#import <objc/message.h>

static NSMutableDictionary *propertyInspectorCache = nil;

Class RKKeyValueCodingClassForObjCType(const char *type)
{
    if (type) {
        // https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        switch (type[0]) {
            case '@': {
                char *openingQuoteLoc = strchr(type, '"');
                if (openingQuoteLoc) {
                    char *closingQuoteLoc = strchr(openingQuoteLoc+1, '"');
                    if (closingQuoteLoc) {
                        size_t classNameStrLen = closingQuoteLoc-openingQuoteLoc;
                        char className[classNameStrLen];
                        memcpy(className, openingQuoteLoc+1, classNameStrLen-1);
                        // Null-terminate the array to stringify
                        className[classNameStrLen-1] = '\0';
                        return objc_getClass(className);
                    }
                }
                // If there is no quoted class type (id), it can be used as-is.
                return Nil;
            }
                
            case 'c': // char
            case 'C': // unsigned char
            case 's': // short
            case 'S': // unsigned short
            case 'i': // int
            case 'I': // unsigned int
            case 'l': // long
            case 'L': // unsigned long
            case 'q': // long long
            case 'Q': // unsigned long long
            case 'f': // float
            case 'd': // double
                return [NSNumber class];
                
            case 'B': // C++ bool or C99 _Bool
                return objc_getClass("NSCFBoolean")
                ?: objc_getClass("__NSCFBoolean")
                ?: [NSNumber class];
                
            case '{': // struct
            case 'b': // bitfield
            case '(': // union
                return [NSValue class];
                
            case '[': // c array
            case '^': // pointer
            case 'v': // void
            case '*': // char *
            case '#': // Class
            case ':': // selector
            case '?': // unknown type (function pointer, etc)
            default:
                break;
        }
    }
    return Nil;
}

@implementation GGPropertyInspector {
	NSMutableDictionary *_properties;
}

+ (id)inspectorForClass:(Class)class {
	if (!class) {
		return nil;
	}
	
	id obj = [self cachedInspectorForKey:class];
	if (!obj) {
		obj = [[GGObjectPropertyInspector alloc] initWithClass:class];
		[self cacheInspector:obj forKey:class];
	}
	
	return obj;
}

+ (id)inspectorForEntity:(NSEntityDescription *)entity {
	if (!entity) {
		return nil;
	}
		
	id obj = [self cachedInspectorForKey:entity.name];
	if (!obj) {
		if ([entity.managedObjectClassName isEqualToString:@"NSManagedObject"]) {
			obj = [[GGManagedObjectPropertyInspector alloc] initWithEntity:entity];
		} else {
			obj = [[GGObjectPropertyInspector alloc] initWithClass:NSClassFromString(entity.managedObjectClassName)];
		}
		
		[self cacheInspector:obj forKey:entity.name];
	}
	
	return obj;
}

+ (id)cachedInspectorForKey:(id)key {
	return propertyInspectorCache[key];
}

+ (void)cacheInspector:(id)inspector forKey:(id)key {
	if (!inspector || !key) {
		return;
	}
	if (!propertyInspectorCache) {
		propertyInspectorCache = [[NSMutableDictionary alloc] initWithCapacity:20];
	}
	propertyInspectorCache[key] = inspector;
}

+ (Class)classFromPropertyAttributeString:(const char *)attr {
	if (attr) {
        const char *typeIdentifierLoc = strchr(attr, 'T');
        if (typeIdentifierLoc) {
            return RKKeyValueCodingClassForObjCType(typeIdentifierLoc+1);
        }
    }
    return Nil;
}

#pragma mark -

- (id)init {
	self = [super init];
	if (self) {
		_properties = [[NSMutableDictionary alloc] initWithCapacity:100];
	}
	return self;
}

- (BOOL)hasProperty:(NSString *)propertyName {
	return (_properties[propertyName] != nil);
}

- (Class)classOfProperty:(NSString *)propertyName {
	Class class = _properties[propertyName];
	if ([class isSubclassOfClass:[GGPropertyInspectorUnknownClass class]]) {
		class = nil;
	}
	return class;
}

- (void)setClass:(Class)class forProperty:(NSString *)propertyName {
	if (!class || !propertyName) {
		return;
	}
	_properties[propertyName] = class;
}

- (NSArray *)properties {
	return [_properties allKeys];
}

@end
