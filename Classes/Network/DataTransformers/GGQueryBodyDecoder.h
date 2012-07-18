//
//  GGQueryBodyDecoder.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGQueryBodyDecoder <NSObject>
+ (id)decode:(NSData *)data error:(NSError **)error;
@end
