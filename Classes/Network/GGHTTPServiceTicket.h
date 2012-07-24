//
//  GGHTTPServiceTicket.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 10.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPQuery;

@interface GGHTTPServiceTicket : NSObject

@property(nonatomic, strong) GGHTTPQuery *query;
@property(nonatomic, assign, getter = isUsed) BOOL used;

@end
