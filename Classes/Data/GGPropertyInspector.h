//
//  GGPropertyInspector.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//
//	Most of the code for this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import <Foundation/Foundation.h>

@class NSEntityDescription;

@interface GGPropertyInspector : NSObject

+ (id)inspectorForEntity:(NSEntityDescription *)entity;
+ (id)inspectorForClass:(Class)class;

- (NSArray *)properties;

- (BOOL)hasProperty:(NSString *)propertyName;
- (Class)classOfProperty:(NSString *)propertyName;

@end
