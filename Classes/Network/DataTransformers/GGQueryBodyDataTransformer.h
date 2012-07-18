//
//  GGQueryBodyDataTransformer.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GGQueryBodyDecoder.h"
#import "GGQueryBodyEncoder.h"

@interface GGQueryBodyDataTransformer : NSObject <GGQueryBodyEncoder, GGQueryBodyDecoder>

@end
