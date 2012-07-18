//
//  NSURL+QueryParameters.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.06.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (NSURL_QueryParameters)

+ (NSURL *)URLWithString:(NSString *)urlString
         queryParameters:(NSDictionary *)queryParameters;

- (NSURL *)URLByAddingQueryParams:(NSDictionary *)queryParameters;

@end
