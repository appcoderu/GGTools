//
//  GGObjectPropertyInspector.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 12/13/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//
//	Most of the code for this class is taken from RestKit
//	https://github.com/RestKit/RestKit

#import "GGPropertyInspector.h"

@interface GGObjectPropertyInspector : GGPropertyInspector

- (id)initWithClass:(Class)aClass;

@end
