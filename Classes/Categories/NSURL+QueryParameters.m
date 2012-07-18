//
//  NSURL+QueryParameters.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 03.06.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import "NSURL+QueryParameters.h"

#import "NSDictionary+URL.h"

@implementation NSURL (NSURL_QueryParameters)

+ (NSURL *)URLWithString:(NSString *)urlString
         queryParameters:(NSDictionary *)queryParameters {
	
	return [[[self class] URLWithString:urlString] URLByAddingQueryParams:queryParameters];
}

- (NSURL *)URLByAddingQueryParams:(NSDictionary *)queryParameters {
	NSString *strParams = [queryParameters componentsAsParameterString];
	
	if (!strParams || [strParams length] == 0) {
		return self;
	}
		
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self absoluteString], strParams]];
}

@end
