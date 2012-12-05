//
//  GGResourcePropertyMapping.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGResourceConfig;

@interface GGResourcePropertyMapping : NSObject

@property(nonatomic, strong) NSString *sourceKeyPath;

@property(nonatomic, strong) NSString *destinationKeyPath;
@property(nonatomic, strong) GGResourceConfig *destinationConfig;

@end
