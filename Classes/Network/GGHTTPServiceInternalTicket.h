//
//  GGHTTPServiceInternalTicket.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 8/27/12.
//  Copyright (c) 2012 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPQuery;
@class GGHTTPServiceTicket;
@class GGHTTPCacheItem;

@protocol GGHTTPFetcherProtocol;

@interface GGHTTPServiceInternalTicket : NSObject

+ (id)ticketWithQuery:(GGHTTPQuery *)query;

- (id)initWithQuery:(GGHTTPQuery *)query;

- (void)addClientTicket:(GGHTTPServiceTicket *)ticket;
- (void)removeClientTicket:(GGHTTPServiceTicket *)ticket;
- (void)removeAllClientTickets;

@property (nonatomic, readonly, strong) GGHTTPQuery *query;
@property (nonatomic, strong) NSObject <GGHTTPFetcherProtocol> *fetcher;

@property (nonatomic, strong) GGHTTPCacheItem *cachedItem;

@property (nonatomic, strong, readonly) NSArray *clientTickets;

@property (nonatomic, assign, getter = isUsed) BOOL used;

@end
