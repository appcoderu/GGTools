//
//  TestItemModel.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "GGTestTest.h"

@class TestCityModel, TestItemDetailsModel, TestMetroModel, TestRubricModel;

@interface TestItemModel : GGTestTest

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * price;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSNumber * modified;
@property (nonatomic, retain) id location;
@property (nonatomic, retain) id fields;
@property (nonatomic, retain) TestItemDetailsModel *details;
@property (nonatomic, retain) TestRubricModel *rubric;
@property (nonatomic, retain) TestCityModel *city;
@property (nonatomic, retain) NSSet *metro;
@end

@interface TestItemModel (CoreDataGeneratedAccessors)

- (void)addMetroObject:(TestMetroModel *)value;
- (void)removeMetroObject:(TestMetroModel *)value;
- (void)addMetro:(NSSet *)values;
- (void)removeMetro:(NSSet *)values;

@end
