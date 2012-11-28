//
//  TestItemDetailsModel.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestItemModel;

@interface TestItemDetailsModel : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) TestItemModel *item;

@end
