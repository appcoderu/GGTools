//
//  GGHTTPQueryResult.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 19.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGHTTPQuery;
@class GGHTTPCacheItem;

@interface GGHTTPQueryResult : NSObject

+ (id)queryResultWithError:(NSError *)error;

@property(nonatomic, strong, readonly) id data;
@property(nonatomic, strong) NSData *rawData;

@property(nonatomic, assign) NSInteger statusCode;
@property(nonatomic, strong) NSDictionary *responseHeaders;

@property(nonatomic, strong) NSError *error;

@property(nonatomic, strong) GGHTTPCacheItem *cacheItem;
@property(nonatomic, assign, readonly, getter = isCached) BOOL cached;

@property(nonatomic, strong) GGHTTPQuery *query;

@end
