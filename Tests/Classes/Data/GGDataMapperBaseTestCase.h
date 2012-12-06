//
//  GGDataMapperBaseTestCase.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/6/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataBaseTestCase.h"

@class GGResourceConfig;

@interface GGDataMapperBaseTestCase : GGDataBaseTestCase

- (id)dataForResource:(NSString *)resourceName;
- (GGResourceConfig *)geoConfig;
- (GGResourceConfig *)geoTreeConfig;
- (GGResourceConfig *)rubricsConfig;
- (GGResourceConfig *)itemsConfig;
- (GGResourceConfig *)servicesConfig;

@end
