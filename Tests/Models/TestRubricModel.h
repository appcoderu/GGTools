//
//  TestRubricModel.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestItemModel;

@interface TestRubricModel : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSSet *items;
@end

@interface TestRubricModel (CoreDataGeneratedAccessors)

- (void)addItemsObject:(TestItemModel *)value;
- (void)removeItemsObject:(TestItemModel *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
