//
//  TestItemModel.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "TestItemModel.h"
#import "TestCityModel.h"
#import "TestItemDetailsModel.h"
#import "TestMetroModel.h"
#import "TestRubricModel.h"


@implementation TestItemModel

@dynamic identifier;
@dynamic title;
@dynamic price;
@dynamic color;
@dynamic createdDate;
@dynamic updatedDate;
@dynamic modified;
@dynamic location;
@dynamic fields;
@dynamic details;
@dynamic rubric;
@dynamic city;
@dynamic metro;
@dynamic services;

@synthesize master=_master;
@synthesize masters=_masters;

@end
