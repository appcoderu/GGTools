//
//  GGResourceConfig.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/22/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	GGResourceImportPolicyNone					= 0UL,
	GGResourceImportPolicyAdd					= 1UL << 0,
	GGResourceImportPolicyDelete				= 1UL << 1,
	GGResourceImportPolicyPrefetch				= 1UL << 2,
	GGResourceImportPolicyFetchByPrimaryKey		= 1UL << 3,
		
	GGResourceImportPolicyDefault		= (GGResourceImportPolicyAdd |
										   GGResourceImportPolicyDelete |
										   GGResourceImportPolicyPrefetch)
} GGResourceImportPolicy;

@interface GGResourceConfig : NSObject

@property(nonatomic, assign) GGResourceImportPolicy importPolicy;
@property(nonatomic, strong) NSString *entityName;

@property(nonatomic, strong) NSArray *mappings;

@property(nonatomic, strong) NSString *primaryKey;
@property(nonatomic, strong) NSString *propertyToDeleteObject;

- (void)mapKeyPath:(NSString *)sourceKeyPath
		toProperty:(NSString *)destinationProperty;

- (void)mapKeyPath:(NSString *)sourceKeyPath
		toProperty:(NSString *)destinationProperty
			config:(GGResourceConfig *)resourceConfig;

- (void)mapProperties:(NSString *)propertyKey, ... NS_REQUIRES_NIL_TERMINATION;

- (NSString *)keyPathForProperty:(NSString *)attributeName;

@end
