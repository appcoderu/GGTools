//
//  GGResourceConfig.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/22/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGResourceConfig.h"
#import "GGResourcePropertyMapping.h"

@implementation GGResourceConfig {
	NSMutableArray *_mappings;
}

- (id)init {
    self = [super init];
    if (self) {
        _importPolicy = GGResourceImportPolicyDefault;
		_mappings = [[NSMutableArray alloc] initWithCapacity:30];
    }
    return self;
}

- (void)mapKeyPath:(NSString *)sourceKeyPath toProperty:(NSString *)destinationProperty {
	[self mapKeyPath:sourceKeyPath toProperty:destinationProperty config:nil];
}

- (void)mapKeyPath:(NSString *)sourceKeyPath toProperty:(NSString *)destinationProperty config:(GGResourceConfig *)resourceConfig {
	if (!sourceKeyPath) {
		return;
	}
	
	if (!destinationProperty) {
		destinationProperty = sourceKeyPath;
	}
	
	GGResourcePropertyMapping *mapping = [[GGResourcePropertyMapping alloc] init];
	mapping.sourceKeyPath = sourceKeyPath;
	mapping.destinationKeyPath = destinationProperty;
	mapping.destinationConfig = resourceConfig;
	
	[_mappings addObject:mapping];
}

- (void)mapProperties:(NSString *)propertyKeyPath, ... {
    va_list args;
    va_start(args, propertyKeyPath);
    for (NSString *keyPath = propertyKeyPath; keyPath != nil; keyPath = va_arg(args, NSString *)) {
		[self mapKeyPath:keyPath toProperty:keyPath];
    }
    va_end(args);
}

- (NSString *)keyPathForProperty:(NSString *)propertyName {
	if (!propertyName) {
		return nil;
	}
	
	for (GGResourcePropertyMapping *mapping in _mappings) {
		if ([mapping.destinationKeyPath isEqualToString:propertyName]) {
			return mapping.sourceKeyPath;
		}
	}
	
	return nil;
}

@end
