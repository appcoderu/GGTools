//
//  NSDate+Extra.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 26.07.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_Extra)

+ (NSDate *)dateFromRelativeDateString:(NSString *)dateStr;
+ (NSDate *)dateFromRFC3339String:(NSString *)dateStr;
- (NSString *)RFC3339String;

- (NSString *)RFC2822String;

@end
