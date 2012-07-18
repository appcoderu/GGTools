//
//  GGHTTPQueryBodyDataTransformer.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"

@interface GGHTTPQueryBodyDataTransformer : NSObject <GGHTTPQueryBodyEncoder, GGHTTPQueryBodyDecoder>

@end
