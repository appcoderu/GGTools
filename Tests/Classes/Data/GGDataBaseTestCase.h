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

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) GGDataStorage *dataStorage;

@end
