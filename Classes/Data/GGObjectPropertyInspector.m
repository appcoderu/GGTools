//
//  GGObjectPropertyInspector.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/13/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//
//	Most of the code for this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGObjectPropertyInspector.h"
#import "GGPropertyInspector+Protected.h"
#import "GGPropertyInspectorUnknownClass.h"

#import <objc/message.h>

@implementation GGObjectPropertyInspector {
	Class _class;
}

- (id)initWithClass:(Class)aClass {
	self = [super init];
	if (self) {
		_class = aClass;
		if (!_class) {
			return nil;
		}
		[self inspect];
	}
	return self;
}

- (void)inspect {
	static NSMutableArray *breakClasses = nil;
	if (!breakClasses) {
		breakClasses = [NSMutableArray arrayWithCapacity:2];
		[breakClasses addObject:[NSObject class]];
		Class managedObjectClass = NSClassFromString(@"NSManagedObject");
		if (managedObjectClass) {
			[breakClasses addObject:managedObjectClass];
		}
	}
	
    Class currentClass = _class;
    while (currentClass != nil) {
		if ([breakClasses containsObject:currentClass]) {
			break;
		}

        // Get the raw list of properties
        unsigned int outCount = 0;
        objc_property_t *propList = class_copyPropertyList(currentClass, &outCount);
		
        // Collect the property names
        for (typeof(outCount) i = 0; i < outCount; i++) {
            objc_property_t *prop = propList + i;
            const char *propName = property_getName(*prop);
			
            if (strcmp(propName, "_mapkit_hasPanoramaID") == 0) {
				continue;
			}
			
			const char *attr = property_getAttributes(*prop);
			if (!attr) {
				continue;
			}
			
			Class aClass = [[self class] classFromPropertyAttributeString:attr];
			if (!aClass) {
				aClass = [GGPropertyInspectorUnknownClass class];
			}
			
			NSString *propNameObj = [[NSString alloc] initWithCString:propName
															 encoding:NSUTF8StringEncoding];
			if (!propNameObj) {
				continue;
			}
			
			[self setClass:aClass forProperty:propNameObj];
        }
		
        free(propList);
        currentClass = [currentClass superclass];
    }
}



@end
