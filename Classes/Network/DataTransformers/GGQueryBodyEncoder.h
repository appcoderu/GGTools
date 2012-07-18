//
//  GGQueryBodyEncoder.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 03.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGQueryBody;

@protocol GGQueryBodyEncoder <NSObject>
+ (GGQueryBody *)encode:(id)bodyObject error:(NSError **)error;
@end
