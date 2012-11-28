//
//  GGObjectPropertyInspector.h
//
//  Created by Evgeniy Shurakov on 11/23/12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//
//	Code is partially taken from RestKit
//	https://github.com/RestKit/RestKit

#import <Foundation/Foundation.h>

@class NSEntityDescription;

@interface GGObjectPropertyInspector : NSObject

+ (id)inspectorForEntity:(NSEntityDescription *)entity;

- (NSArray *)properties;

- (BOOL)hasProperty:(NSString *)property;
- (Class)classOfProperty:(NSString *)propertyName;

@end
