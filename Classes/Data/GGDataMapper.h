//
//  GGDataMapper.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/29/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGDataStorage;
@class GGResourceConfig;

@interface GGDataMapper : NSObject

@property(nonatomic, strong, readonly) GGDataStorage *dataStorage;

- (id)initWithDataStorage:(GGDataStorage *)dataStorage;

- (id)mapData:(id)data resourceConfig:(GGResourceConfig *)config error:(NSError **)error;

@end
