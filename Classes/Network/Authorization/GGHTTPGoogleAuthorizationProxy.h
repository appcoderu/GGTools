//
//  GGHTTPGoogleAuthorizationProxy.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 21.07.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTMHTTPFetcher.h"

@protocol GGHTTPAuthorizationProtocol;

@interface GGHTTPGoogleAuthorizationProxy : NSObject <GTMFetcherAuthorizationProtocol>

- (id)initWithAuthorizer:(NSObject <GGHTTPAuthorizationProtocol> *)authorizer;

@property(nonatomic, strong) NSObject <GGHTTPAuthorizationProtocol> *authorizer;

@end
