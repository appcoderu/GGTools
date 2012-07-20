//
//  NSDate+Extra.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 26.07.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (NSDate_GGExtra)

+ (NSDate *)gg_dateFromRelativeDateString:(NSString *)dateStr;
+ (NSDate *)gg_dateFromRFC3339String:(NSString *)dateStr;
- (NSString *)gg_RFC3339String;

- (NSString *)gg_RFC2822String;

@end
