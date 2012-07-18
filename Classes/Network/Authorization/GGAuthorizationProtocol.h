//
//  GGAuthorizationProtocol.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 04.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GTMHTTPFetcher.h"

static NSString * const GGAuthorizationErrorDomain = @"ru.ruru.authorization";
static NSString * const GGAuthorizationErrorRequestKey = @"request";

static const NSUInteger GGAuthorizationErrorAuthorizationFailed = -1001;

@protocol GGAuthorizationProtocol <GTMFetcherAuthorizationProtocol>

@end
