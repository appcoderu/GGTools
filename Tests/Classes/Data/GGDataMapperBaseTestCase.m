//
//  GGDataMapperBaseTestCase.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/6/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapperBaseTestCase.h"

#import "GGResourceConfig.h"

@implementation GGDataMapperBaseTestCase

- (id)dataForResource:(NSString *)resourceName {
	NSString *path = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Web/api"];
	
	NSString *filename = [[path stringByAppendingPathComponent:resourceName] stringByAppendingPathExtension:@"json"];
	
	NSError *error = nil;
	id data = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filename]
											  options:0
												error:&error];
	GHAssertNotNil(data, @"json data is nil");
	GHAssertNil(error, @"json error: %@", error);
	
	return data;
}

- (GGResourceConfig *)geoConfig {
	GGResourceConfig *citiesConfig = [[GGResourceConfig alloc] init];
	[citiesConfig setEntityName:@"TestCity"];
	[citiesConfig setPrimaryKey:@"identifier"];
	[citiesConfig mapKeyPath:@"id" toProperty:@"identifier"];
	[citiesConfig mapKeyPath:@"location.lat" toProperty:@"lat"];
	[citiesConfig mapKeyPath:@"location.lng" toProperty:@"lon"];
	[citiesConfig mapProperties:@"title", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[metroConfig mapKeyPath:@"id" toProperty:@"identifier"];
	[metroConfig mapProperties:@"title", nil];
	
	GGResourceConfig *metroCityConfig = [[GGResourceConfig alloc] init];
	[metroCityConfig setEntityName:@"TestCity"];
	[metroCityConfig setPrimaryKey:@"identifier"];
	
	[metroConfig mapKeyPath:@"cityId" toProperty:@"city" config:metroCityConfig];
	
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config mapKeyPath:@"cities" toProperty:@"cities" config:citiesConfig];
	[config mapKeyPath:@"metro" toProperty:@"metro" config:metroConfig];
	
	return config;
}

- (GGResourceConfig *)geoTreeConfig {
	GGResourceConfig *citiesConfig = [[GGResourceConfig alloc] init];
	[citiesConfig setEntityName:@"TestCity"];
	[citiesConfig setPrimaryKey:@"identifier"];
	[citiesConfig mapKeyPath:@"id" toProperty:@"identifier"];
	[citiesConfig mapKeyPath:@"location.lat" toProperty:@"lat"];
	[citiesConfig mapKeyPath:@"location.lng" toProperty:@"lon"];
	[citiesConfig mapProperties:@"title", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[metroConfig mapKeyPath:@"id" toProperty:@"identifier"];
	[metroConfig mapProperties:@"title", nil];
	
	[citiesConfig mapKeyPath:@"metro" toProperty:@"metro" config:metroConfig];
	
	return citiesConfig;
}

- (GGResourceConfig *)rubricsConfig {
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config setEntityName:@"TestRubric"];
	[config setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"id" toProperty:@"identifier"];
	[config mapProperties:@"title", nil];
	return config;
}

- (GGResourceConfig *)servicesConfig {
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config setEntityName:@"TestService"];
	[config setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"id" toProperty:@"identifier"];
	[config mapProperties:@"title", nil];
	return config;
}

- (GGResourceConfig *)itemsConfig {
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config setEntityName:@"TestItem"];
	[config setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"id" toProperty:@"identifier"];
	[config mapProperties:@"title", @"price", @"modified", @"location", @"fields", @"createdDate", @"updatedDate", @"color", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"metro" toProperty:@"metro" config:metroConfig];
	
	GGResourceConfig *cityConfig = [[GGResourceConfig alloc] init];
	[cityConfig setEntityName:@"TestCity"];
	[cityConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"cityId" toProperty:@"city" config:cityConfig];
	
	GGResourceConfig *rubricConfig = [[GGResourceConfig alloc] init];
	[rubricConfig setEntityName:@"TestRubric"];
	[rubricConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"rubricId" toProperty:@"rubric" config:rubricConfig];
	
	GGResourceConfig *serviceConfig = [[GGResourceConfig alloc] init];
	[serviceConfig setEntityName:@"TestService"];
	[serviceConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"services" toProperty:@"services" config:serviceConfig];
	
	return config;
}

@end
