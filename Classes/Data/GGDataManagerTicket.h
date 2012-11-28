//
//  GGDataManagerTicket.h
//
//  Created by Evgeniy Shurakov on 11.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGDataManagerTicket : NSObject

+ (id)ticketWithKey:(NSString *)key completionHandler:(id)handler;

- (id)initWithKey:(NSString *)key completionHandler:(id)handler;

@property (nonatomic, readonly, strong) NSString *key;
@property (nonatomic, readonly, strong) id completionHandler;

@end
