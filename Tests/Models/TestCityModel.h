//
//  TestCityModel.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestItemModel, TestMetroModel;

@interface TestCityModel : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * lat;
@property (nonatomic, retain) NSNumber * lon;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, retain) NSSet *metro;
@end

@interface TestCityModel (CoreDataGeneratedAccessors)

- (void)addItemsObject:(TestItemModel *)value;
- (void)removeItemsObject:(TestItemModel *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

- (void)addMetroObject:(TestMetroModel *)value;
- (void)removeMetroObject:(TestMetroModel *)value;
- (void)addMetro:(NSSet *)values;
- (void)removeMetro:(NSSet *)values;

@end
