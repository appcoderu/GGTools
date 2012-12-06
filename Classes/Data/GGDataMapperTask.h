//
//  GGDataMapperTask.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/6/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGDataStorage;
@class GGResourceConfig;

@interface GGDataMapperTask : NSObject

@property(nonatomic, strong, readonly) GGDataStorage *dataStorage;
@property(nonatomic, strong, readonly) GGResourceConfig *resourceConfig;

@property(nonatomic, strong, readonly) id sourceData;
@property(nonatomic, strong, readonly) id resultData;

- (id)initWithData:(id)sourceData
	resourceConfig:(GGResourceConfig *)resourceConfig
	   dataStorage:(GGDataStorage *)dataStorage;

- (void)execute;

@end
