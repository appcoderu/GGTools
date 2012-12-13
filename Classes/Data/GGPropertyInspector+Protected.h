//
//  GGPropertyInspector+Protected.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/13/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import "GGPropertyInspector.h"

@interface GGPropertyInspector (Protected)

+ (Class)classFromPropertyAttributeString:(const char *)attr;

- (void)setClass:(Class)class forProperty:(NSString *)propertyName;

@end
