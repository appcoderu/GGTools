//
//  GGDataMapper.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/29/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGDataMapper.h"

#import "GGDataStorage.h"
#import "GGResourceConfig.h"
#import "GGPropertyInspector.h"
#import "GGResourcePropertyMapping.h"

#import "GGDataMapperTask.h"

#import "NSError+GGExtra.h"

@implementation GGDataMapper {
	
}

- (id)init {
	return [self initWithDataStorage:nil];
}

- (id)initWithDataStorage:(GGDataStorage *)dataStorage {
	self = [super init];
	if (self) {
		_dataStorage = dataStorage;
	}
	return self;
}

- (id)mapData:(id)data resourceConfig:(GGResourceConfig *)config error:(NSError **)error {
	GGDataMapperTask *task = [[GGDataMapperTask alloc] initWithData:data
													 resourceConfig:config
														dataStorage:self.dataStorage];
	[task execute];
	
	return task.resultData;
}

@end
