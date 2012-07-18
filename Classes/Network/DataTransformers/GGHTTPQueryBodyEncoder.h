//
//  GGHTTPQueryBodyEncoder.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPQueryBody;

@protocol GGHTTPQueryBodyEncoder <NSObject>
+ (GGHTTPQueryBody *)encode:(id)bodyObject error:(NSError **)error;
@end
