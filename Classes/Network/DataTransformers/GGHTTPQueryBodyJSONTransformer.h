//
//  GGHTTPQueryBodyJSONTransformer.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"

@interface GGHTTPQueryBodyJSONTransformer : NSObject <GGHTTPQueryBodyDecoder, GGHTTPQueryBodyEncoder>

@end
