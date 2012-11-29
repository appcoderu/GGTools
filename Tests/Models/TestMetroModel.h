//
//  TestMetroModel.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestCityModel, TestItemModel;

@interface TestMetroModel : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) TestCityModel *city;
@property (nonatomic, retain) NSSet *items;
@end

@interface TestMetroModel (CoreDataGeneratedAccessors)

- (void)addItemsObject:(TestItemModel *)value;
- (void)removeItemsObject:(TestItemModel *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
