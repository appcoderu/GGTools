//
//  NSURL+QueryParameters.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.06.11.
//  Copyright 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (NSURL_GGQueryParameters)

+ (NSURL *)gg_URLWithString:(NSString *)urlString
         queryParameters:(NSDictionary *)queryParameters;

- (NSURL *)gg_URLByAddingQueryParams:(NSDictionary *)queryParameters;

@end
