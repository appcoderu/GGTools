//
//  GGResourceConfig.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/22/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	GGResourceImportPolicyNone			= 0UL,
	GGResourceImportPolicyAdd			= 1UL << 0,
	GGResourceImportPolicyDelete		= 1UL << 1,
	GGResourceImportPolicyPrefetch		= 1UL << 2,
	GGResourceImportPolicyFetchByPK		= 1UL << 3,
	
	
	GGResourceImportPolicySync			= (GGResourceImportPolicyAdd |
										   GGResourceImportPolicyDelete |
										   GGResourceImportPolicyPrefetch),
	
	GGResourceImportPolicyIncremental	= (GGResourceImportPolicyAdd |
										   GGResourceImportPolicyFetchByPK)
} GGResourceImportPolicy;

@interface GGResourceConfig : NSObject

@property(nonatomic, assign) GGResourceImportPolicy importPolicy;
@property(nonatomic, strong) NSString *entityName;

@property(nonatomic, strong) NSArray *attributeMappings;

@property(nonatomic, strong) NSString *primaryKey;

- (void)mapKeyPath:(NSString *)sourceKeyPath
	   toAttribute:(NSString *)destinationAttribute;

- (void)mapKeyPath:(NSString *)sourceKeyPath
	   toAttribute:(NSString *)destinationAttribute
			config:(GGResourceConfig *)resourceConfig;

- (void)mapAttributes:(NSString *)attributeKey, ... NS_REQUIRES_NIL_TERMINATION;

- (NSString *)keyPathForAttribute:(NSString *)attributeName;

@end
