//
//  NSString+Escape.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 29.12.10.
//  Copyright 2010 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Escape)

+ (NSString *)stringByURLEncodingString:(NSString *)str;
+ (NSString *)stringByURLEncodingForURI:(NSString *)str;

@end
