//
//  GGHTTPServiceTicket+Private.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGHTTPFetcherProtocol;

@interface GGHTTPServiceTicket (Private)

@property(nonatomic, strong) NSObject <GGHTTPFetcherProtocol> *fetcher;


@end