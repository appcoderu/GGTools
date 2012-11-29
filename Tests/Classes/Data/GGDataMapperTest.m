//
//  GGDataMapperTest.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/29/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapperTest.h"

#import "GGResourceConfig.h"
#import "GGDataMapper.h"

#import "TestMetroModel.h"
#import "TestCityModel.h"
#import "TestRubricModel.h"
#import "TestItemModel.h"
#import "TestItemDetailsModel.h"

@implementation GGDataMapperTest

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
	[citiesConfig mapKeyPath:@"id" toAttribute:@"identifier"];
	[citiesConfig mapKeyPath:@"location.lat" toAttribute:@"lat"];
	[citiesConfig mapKeyPath:@"location.lng" toAttribute:@"lon"];
	[citiesConfig mapAttributes:@"title", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[metroConfig mapKeyPath:@"id" toAttribute:@"identifier"];
	[metroConfig mapAttributes:@"title", nil];
	
	GGResourceConfig *metroCityConfig = [[GGResourceConfig alloc] init];
	[metroCityConfig setEntityName:@"TestCity"];
	[metroCityConfig setPrimaryKey:@"identifier"];
	
	[metroConfig mapKeyPath:@"cityId" toAttribute:@"city" config:metroCityConfig];
	
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config mapKeyPath:@"cities" toAttribute:@"cities" config:citiesConfig];
	[config mapKeyPath:@"metro" toAttribute:@"metro" config:metroConfig];
	
	return config;
}

- (GGResourceConfig *)geoTreeConfig {
	GGResourceConfig *citiesConfig = [[GGResourceConfig alloc] init];
	[citiesConfig setEntityName:@"TestCity"];
	[citiesConfig setPrimaryKey:@"identifier"];
	[citiesConfig mapKeyPath:@"id" toAttribute:@"identifier"];
	[citiesConfig mapKeyPath:@"location.lat" toAttribute:@"lat"];
	[citiesConfig mapKeyPath:@"location.lng" toAttribute:@"lon"];
	[citiesConfig mapAttributes:@"title", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[metroConfig mapKeyPath:@"id" toAttribute:@"identifier"];
	[metroConfig mapAttributes:@"title", nil];
	
	[citiesConfig mapKeyPath:@"metro" toAttribute:@"metro" config:metroConfig];

	return citiesConfig;
}

- (GGResourceConfig *)rubricsConfig {
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config setEntityName:@"TestRubric"];
	[config setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"id" toAttribute:@"identifier"];
	[config mapAttributes:@"title", nil];
	return config;
}

- (GGResourceConfig *)itemsConfig {
	GGResourceConfig *config = [[GGResourceConfig alloc] init];
	[config setEntityName:@"TestItem"];
	[config setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"id" toAttribute:@"identifier"];
	[config mapAttributes:@"title", @"price", @"modified", @"location", @"fields", @"createdDate", @"updatedDate", @"color", nil];
	
	GGResourceConfig *metroConfig = [[GGResourceConfig alloc] init];
	[metroConfig setEntityName:@"TestMetro"];
	[metroConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"metro" toAttribute:@"metro" config:metroConfig];
	
	GGResourceConfig *cityConfig = [[GGResourceConfig alloc] init];
	[cityConfig setEntityName:@"TestCity"];
	[cityConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"cityId" toAttribute:@"city" config:cityConfig];
	
	GGResourceConfig *rubricConfig = [[GGResourceConfig alloc] init];
	[rubricConfig setEntityName:@"TestRubric"];
	[rubricConfig setPrimaryKey:@"identifier"];
	[config mapKeyPath:@"rubricId" toAttribute:@"rubric" config:rubricConfig];
	
	return config;
}

- (void)testPlainGeoImport {
	GGResourceConfig *config = [self geoConfig];
	GHAssertNotNil(config, nil);
	
	GGDataMapper *mapper = [[GGDataMapper alloc] initWithDataStorage:self.dataStorage];
	GHAssertNotNil(mapper, nil);
	
	NSError *error = nil;
	
	NSDictionary *mappedData = [mapper mapData:[self dataForResource:@"geo-plain"]
								resourceConfig:config
										 error:&error];
	
	GHAssertNil(error, @"Map error: %@", error);
	GHAssertNotNil(mappedData, nil);
	GHAssertTrue([mappedData isKindOfClass:[NSDictionary class]], nil);
	GHAssertEquals([mappedData count], (NSUInteger)2, nil);
	
	NSArray *cities = [mappedData objectForKey:@"cities"];
	NSArray *metro = [mappedData objectForKey:@"metro"];
	
	GHAssertNotNil(cities, nil);
	GHAssertTrue([cities isKindOfClass:[NSArray class]], nil);
	GHAssertEquals([cities count], (NSUInteger)4, nil);
	
	GHAssertNotNil(metro, nil);
	GHAssertTrue([metro isKindOfClass:[NSArray class]], nil);
	GHAssertEquals([metro count], (NSUInteger)4, nil);
	
	cities = [cities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	metro = [metro sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	
	TestMetroModel *metroObj = metro[0];
	GHAssertNotNil(metroObj, nil);
	GHAssertEqualObjects(metroObj.identifier, @(1), nil);
	GHAssertEqualObjects(metroObj.title, @"metro 1", nil);
	GHAssertEqualObjects(metroObj.city, cities[0], nil);
	
	metroObj = metro[2];
	GHAssertNotNil(metroObj, nil);
	GHAssertEqualObjects(metroObj.identifier, @(3), nil);
	GHAssertEqualObjects(metroObj.title, @"metro 3", nil);
	GHAssertEqualObjects(metroObj.city, cities[1], nil);
	
	TestCityModel *cityObj = cities[0];
	GHAssertNotNil(cityObj, nil);
	GHAssertEqualObjects(cityObj.identifier, @(1), nil);
	GHAssertEqualObjects(cityObj.title, @"city 1", nil);
	GHAssertEquals([cityObj.lat floatValue], 50.123f, nil);
	GHAssertEquals([cityObj.lon floatValue], 51.321f, nil);
	GHAssertNotNil(cityObj.metro, nil);
	GHAssertEquals([cityObj.metro count], (NSUInteger)2, nil);
	
	cityObj = cities[1];
	GHAssertNotNil(cityObj, nil);
	GHAssertEqualObjects(cityObj.identifier, @(2), nil);
	GHAssertEqualObjects(cityObj.title, @"city 2", nil);
	GHAssertEquals([cityObj.lat floatValue], 52.123f, nil);
	GHAssertNil(cityObj.lon, nil);
	GHAssertNotNil(cityObj.metro, nil);
	GHAssertEquals([cityObj.metro count], (NSUInteger)1, nil);
	
	cityObj = cities[3];
	GHAssertNotNil(cityObj, nil);
	GHAssertEqualObjects(cityObj.identifier, @(4), nil);
	GHAssertEqualObjects(cityObj.title, @"city 4", nil);
	GHAssertNil(cityObj.lon, nil);
	GHAssertNil(cityObj.lat, nil);
	if (cityObj.metro) {
		GHAssertEquals([cityObj.metro count], (NSUInteger)0, nil);
	}
}

- (void)testTreeGeoImport {
	GGResourceConfig *config = [self geoTreeConfig];
	GHAssertNotNil(config, nil);
	
	GGDataMapper *mapper = [[GGDataMapper alloc] initWithDataStorage:self.dataStorage];
	GHAssertNotNil(mapper, nil);
	
	NSError *error = nil;
	
	NSArray *cities = [mapper mapData:[self dataForResource:@"geo-tree"]
					   resourceConfig:config
								error:&error];
	
	GHAssertNil(error, @"Map error: %@", error);
	GHAssertNotNil(cities, nil);
	GHAssertTrue([cities isKindOfClass:[NSArray class]], nil);
	GHAssertEquals([cities count], (NSUInteger)3, nil);
	
	cities = [cities sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	
	TestCityModel *cityObj = cities[0];
	GHAssertNotNil(cityObj, nil);
	GHAssertEqualObjects(cityObj.identifier, @(1), nil);
	GHAssertEqualObjects(cityObj.title, @"city 1", nil);
	GHAssertEquals([cityObj.lat floatValue], 50.123f, nil);
	GHAssertEquals([cityObj.lon floatValue], 51.321f, nil);
	GHAssertNotNil(cityObj.metro, nil);
	GHAssertEquals([cityObj.metro count], (NSUInteger)2, nil);
	
	NSArray *metro = [cityObj.metro sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	
	TestMetroModel *metroObj = metro[0];
	GHAssertNotNil(metroObj, nil);
	GHAssertEqualObjects(metroObj.identifier, @(1), nil);
	GHAssertEqualObjects(metroObj.title, @"metro 1", nil);
	GHAssertEqualObjects(metroObj.city, cityObj, nil);
	
	metroObj = metro[1];
	GHAssertNotNil(metroObj, nil);
	GHAssertEqualObjects(metroObj.identifier, @(2), nil);
	GHAssertEqualObjects(metroObj.title, @"metro 2", nil);
	GHAssertEqualObjects(metroObj.city, cityObj, nil);
	
	cityObj = cities[2];
	GHAssertNotNil(cityObj, nil);
	GHAssertEqualObjects(cityObj.identifier, @(3), nil);
	GHAssertEqualObjects(cityObj.title, @"city 3", nil);
	GHAssertNil(cityObj.lon, nil);
	GHAssertNil(cityObj.lat, nil);
	if (cityObj.metro) {
		GHAssertEquals([cityObj.metro count], (NSUInteger)0, nil);
	}
}

- (void)testRubricsImport {
	GGResourceConfig *config = [self rubricsConfig];
	GHAssertNotNil(config, nil);
	
	GGDataMapper *mapper = [[GGDataMapper alloc] initWithDataStorage:self.dataStorage];
	GHAssertNotNil(mapper, nil);
	
	NSError *error = nil;
	NSArray *rubrics = [mapper mapData:[self dataForResource:@"rubrics"]
						resourceConfig:config
								 error:&error];
	
	GHAssertNil(error, @"Map error: %@", error);
	GHAssertNotNil(rubrics, nil);
	GHAssertTrue([rubrics isKindOfClass:[NSArray class]], nil);
	GHAssertEquals([rubrics count], (NSUInteger)4, nil);
	
	rubrics = [rubrics sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	
	TestRubricModel *rubricObj = nil;
	
	for (NSUInteger i = 0; i < 4; ++i) {
		rubricObj = rubrics[i];
		GHAssertNotNil(rubricObj, nil);
		GHAssertEqualObjects(rubricObj.identifier, @(i+1), nil);
		NSString *title = [NSString stringWithFormat:@"rubric %u", (i+1)];
		GHAssertEqualObjects(rubricObj.title, title, nil);
	}
}

- (void)testItemsImport {
	GGDataMapper *mapper = [[GGDataMapper alloc] initWithDataStorage:self.dataStorage];
	GHAssertNotNil(mapper, nil);
		
	[mapper mapData:[self dataForResource:@"geo-plain"]
	 resourceConfig:[self geoConfig]
			  error:nil];
	
	[mapper mapData:[self dataForResource:@"rubrics"]
	 resourceConfig:[self rubricsConfig]
			  error:nil];
	
	NSError *error = nil;
	
	NSArray *items = [mapper mapData:[self dataForResource:@"items"]
					  resourceConfig:[self itemsConfig]
							   error:&error];
	
	GHAssertNil(error, @"Map error: %@", error);
	GHAssertNotNil(items, nil);
	GHAssertTrue([items isKindOfClass:[NSArray class]], nil);
	GHAssertEquals([items count], (NSUInteger)3, nil);
	
	items = [items sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
	
	TestItemModel *itemObj = nil;
	itemObj = items[0];
	GHAssertNotNil(itemObj, nil);
	GHAssertEqualObjects(itemObj.identifier, @(1), nil);
	GHAssertEqualObjects(itemObj.title, @"item 1", nil);
	GHAssertNotNil(itemObj.createdDate, nil);
	GHAssertNotNil(itemObj.updatedDate, nil);
	GHAssertNotNil(itemObj.location, nil);
	GHAssertTrue([itemObj.modified boolValue], nil);
	GHAssertNotNil(itemObj.fields, nil);
	GHAssertTrue([itemObj.fields isKindOfClass:[NSArray class]], nil);
	GHAssertEqualsWithAccuracy(itemObj.price.doubleValue, 1223.32, 0.1, nil);
	GHAssertEquals([itemObj.city.identifier integerValue], (NSInteger)1, nil);
	GHAssertEquals([itemObj.rubric.identifier integerValue], (NSInteger)2, nil);
	GHAssertEquals([itemObj.metro count], (NSUInteger)3, nil);
	
	itemObj = items[2];
	GHAssertNotNil(itemObj, nil);
	GHAssertEqualObjects(itemObj.identifier, @(3), nil);
	GHAssertEqualObjects(itemObj.title, @"item 3", nil);
	GHAssertNotNil(itemObj.createdDate, nil);
	GHAssertEqualsWithAccuracy([itemObj.createdDate timeIntervalSince1970], 12342233.0, 0.1, nil);
	GHAssertNotNil(itemObj.updatedDate, nil);
	GHAssertEqualsWithAccuracy([itemObj.updatedDate timeIntervalSince1970], 12352233.0, 0.1, nil);
	GHAssertNotNil(itemObj.location, nil);
	GHAssertTrue([itemObj.modified boolValue], nil);
	GHAssertNotNil(itemObj.fields, nil);
	GHAssertTrue([itemObj.fields isKindOfClass:[NSDictionary class]], nil);
	GHAssertEqualsWithAccuracy(itemObj.price.doubleValue, 223.55, 0.1, nil);
	GHAssertEquals([itemObj.city.identifier integerValue], (NSInteger)3, nil);
	GHAssertEquals([itemObj.rubric.identifier integerValue], (NSInteger)1, nil);
	GHAssertEquals([itemObj.metro count], (NSUInteger)2, nil);
}

@end
