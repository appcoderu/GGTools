//
//  GGResourceConfig.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/22/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	GGResourceImportPolicyDefault				= -1,
	GGResourceImportPolicyNone					= 0U,
	GGResourceImportPolicyAdd					= 1U << 0,
	GGResourceImportPolicyDelete				= 1U << 1,
	GGResourceImportPolicyPrefetch				= 1U << 2,
	GGResourceImportPolicyFetchByPrimaryKey		= 1U << 3,
} GGResourceImportPolicy;

@interface GGResourceConfig : NSObject

@property(nonatomic, assign) GGResourceImportPolicy importPolicy;
@property(nonatomic, strong) NSString *entityName;

@property(nonatomic, strong) NSArray *mappings;

@property(nonatomic, strong) NSString *primaryKey;
@property(nonatomic, strong) NSString *deleteObjectProperty;
@property(nonatomic, strong) NSString *autoOrderProperty;

- (void)mapKeyPath:(NSString *)sourceKeyPath
		toProperty:(NSString *)destinationProperty;

- (void)mapKeyPath:(NSString *)sourceKeyPath
		toProperty:(NSString *)destinationProperty
			config:(GGResourceConfig *)resourceConfig;

- (void)mapProperties:(NSString *)propertyKey, ... NS_REQUIRES_NIL_TERMINATION;

- (NSString *)keyPathForProperty:(NSString *)attributeName;

@end
