//
//  GGQueryBody.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 02.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGQueryBody : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *contentType;

@end
