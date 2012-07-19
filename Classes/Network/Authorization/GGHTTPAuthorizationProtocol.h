//
//  GGHTTPAuthorizationProtocol.h
//  RuRu
//
//  Created by Evgeniy Shurakov on 04.05.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GGHTTPAuthorizationProtocol <NSObject>

@required
// This protocol allows us to call the authorizer without requiring its sources
// in this project
- (void)authorizeRequest:(NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel;

- (void)stopAuthorization;

- (BOOL)isAuthorizingRequest:(NSURLRequest *)request;

- (BOOL)isAuthorizedRequest:(NSURLRequest *)request;

- (NSString *)userEmail;

@optional

- (BOOL)primeForRefresh;

@end
