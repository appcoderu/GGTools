//
//  GGDataBaseTestCase.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/28/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>

#import "GGDataStorage.h"

#import "TestCityModel.h"
#import "TestItemDetailsModel.h"
#import "TestRubricModel.h"

@interface GGDataBaseTestCase : GHAsyncTestCase

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly, strong, nonatomic) GGDataStorage *dataStorage;

@end
