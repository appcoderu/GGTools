//
//  GGHTTPServiceTicket+Private.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGHTTPFetcherProtocol;
@class GGHTTPServiceInternalTicket;

@interface GGHTTPServiceTicket (Private)

@property(nonatomic, copy) id completionHandler;
@property(nonatomic, weak) GGHTTPServiceInternalTicket *internalTicket;

@end