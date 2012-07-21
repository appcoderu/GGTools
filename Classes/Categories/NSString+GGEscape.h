//
//  NSString+Escape.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 29.12.10.
//  Copyright 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(GGEscape)

+ (NSString *)gg_stringByURLEncodingString:(NSString *)str;
+ (NSString *)gg_stringByURLEncodingForURI:(NSString *)str;

@end
