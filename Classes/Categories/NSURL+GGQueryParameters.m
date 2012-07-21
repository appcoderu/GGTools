//
//  NSURL+QueryParameters.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.06.11.
//  Copyright 2012 AppCode. All rights reserved.
//

#import "NSURL+GGQueryParameters.h"

#import "NSDictionary+GGURL.h"

@implementation NSURL (NSURL_GGQueryParameters)

+ (NSURL *)gg_URLWithString:(NSString *)urlString
         queryParameters:(NSDictionary *)queryParameters {
	
	return [[[self class] URLWithString:urlString] gg_URLByAddingQueryParams:queryParameters];
}

- (NSURL *)gg_URLByAddingQueryParams:(NSDictionary *)queryParameters {
	NSString *strParams = [queryParameters gg_componentsAsParameterString];
	
	if (!strParams || [strParams length] == 0) {
		return self;
	}
		
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self absoluteString], strParams]];
}

@end
