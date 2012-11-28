//
//  GGResourceConfig.m
//
//  Created by Evgeniy Shurakov on 11/22/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGResourceConfig.h"
#import "GGResourceAttributeMapping.h"

@implementation GGResourceConfig {
	NSMutableArray *_attributeMappings;
}

- (id)init {
    self = [super init];
    if (self) {
        _importPolicy = GGResourceImportPolicySync;
		_attributeMappings = [[NSMutableArray alloc] initWithCapacity:30];
    }
    return self;
}

- (void)mapKeyPath:(NSString *)sourceKeyPath toAttribute:(NSString *)destinationAttribute {
	[self mapKeyPath:sourceKeyPath toAttribute:destinationAttribute config:nil];
}

- (void)mapKeyPath:(NSString *)sourceKeyPath toAttribute:(NSString *)destinationAttribute config:(GGResourceConfig *)resourceConfig {
	if (!sourceKeyPath || !destinationAttribute) {
		return;
	}
	
	GGResourceAttributeMapping *mapping = [[GGResourceAttributeMapping alloc] init];
	mapping.sourceKeyPath = sourceKeyPath;
	mapping.destinationKeyPath = destinationAttribute;
	mapping.destinationConfig = resourceConfig;
	
	[_attributeMappings addObject:mapping];
}

- (void)mapAttributes:(NSString *)attributeKeyPath, ... {
    va_list args;
    va_start(args, attributeKeyPath);
    for (NSString *keyPath = attributeKeyPath; keyPath != nil; keyPath = va_arg(args, NSString *)) {
		[self mapKeyPath:keyPath toAttribute:keyPath];
    }
    va_end(args);
}

- (NSString *)keyPathForAttribute:(NSString *)attributeName {
	if (!attributeName) {
		return nil;
	}
	
	for (GGResourceAttributeMapping *mapping in _attributeMappings) {
		if ([mapping.destinationKeyPath isEqualToString:attributeName]) {
			return mapping.sourceKeyPath;
		}
	}
	
	return nil;
}

@end
