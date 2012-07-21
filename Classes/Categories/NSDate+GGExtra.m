//
//  NSDate+Extra.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 26.07.11.
//  Copyright 2012 AppCode. All rights reserved.
//

#import "NSDate+GGExtra.h"

@implementation NSDate (NSDate_GGExtra)

+ (NSDate *)gg_dateFromRelativeDateString:(NSString *)dateStr {
	if (!dateStr) {
		return nil;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:dateStr];
	
	
	BOOL today = [scanner scanString:@"today" intoString:NULL];
	
	BOOL scanResult;
	
	NSString *signChar;
	scanResult = [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-"] 
									 intoString:&signChar];
	if (!scanResult) {
		if (today) {
			return [NSDate date];
		} else {
			return nil;
		}
	}
	
	NSInteger offset;
	scanResult = [scanner scanInteger:&offset];
	if (!scanResult) {
		return nil;
	}
	
	NSString *item;
	scanResult = [scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] 
									 intoString:&item];
	if (!scanResult) {
		return nil;
	}
	
	if ([signChar isEqualToString:@"-"]) {
		offset *= -1;
	}
	
	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	
	if ([item isEqualToString:@"year"] || [item isEqualToString:@"years"]) {
		[dateComponents setYear:offset];
	} else if ([item isEqualToString:@"month"] || [item isEqualToString:@"months"]) {
		[dateComponents setMonth:offset];
	} else if ([item isEqualToString:@"week"] || [item isEqualToString:@"weeks"]) {
		[dateComponents setWeek:offset];
	} else if ([item isEqualToString:@"day"] || [item isEqualToString:@"days"]) {
		[dateComponents setDay:offset];
	} else {
		return nil;
	}
	
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	return [calendar dateByAddingComponents:dateComponents 
									 toDate:[NSDate date] 
									options:0];
}

+ (NSDate *)gg_dateFromRFC3339String:(NSString *)dateStr {
#define ISALNUM(x)  (isalnum((int)  ((unsigned char)x)))
#define ISALPHA(x)  (isalpha((int)  ((unsigned char)x)))
#define ISDIGIT(x)  (isdigit((int)  ((unsigned char)x)))
	
	NSDate *result = nil;
	static const int BUF_SIZE = 128;
	
	NSUInteger length = [dateStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger currentPos = 0;
	
	if (!dateStr || length == 0 || length > BUF_SIZE) {
		return result;
	}
	
	const char *date = [dateStr UTF8String];
	
	
	char alphaBuf[BUF_SIZE];
	char digitBuf[BUF_SIZE];
	
	size_t alphaBufLength = 0;
	size_t digitBufLength = 0;
	
	memset(alphaBuf, 0, BUF_SIZE);
	memset(digitBuf, 0, BUF_SIZE);
	
	int year = 0;
	int month = 0;
	int day = 0;
	int hour = 0;
	int minute = 0;
	int second = 0;
	float millisecond = 0.0f;
	int tzHour = 0;
	int tzMinute = 0;
	int tzSign = 1;
	
	NSTimeZone *tz = nil;
	
	while (*date && !ISDIGIT(*date)) {
		++date;
		++currentPos;
	}
	
	if (3 == sscanf(date, "%04d-%02d-%02d", &year, &month, &day)) {
		if ((currentPos + 10) < length) {
			date += 10;
			currentPos += 10;
			
			if (*date == 'T' && (currentPos + 1) < length) {
				++date;
				++currentPos;
				
				if (3 == sscanf(date, "%02d:%02d:%02d", &hour, &minute, &second)) {
					if ((currentPos + 8) < length) {
						date += 8;
						currentPos += 8;
						
						if (*date == '.') {
							++date;
							while (*date && ISDIGIT(*date)) {
								digitBuf[digitBufLength++] = *date;
								++date;
							}
							
							if (digitBufLength > 0) {
								millisecond = atoi(digitBuf) / powf(10, digitBufLength);
								memset(digitBuf, 0, digitBufLength);
								digitBufLength = 0;
							}
						}
						
						if (*date == '-' || *date == '+') {
							if (*date == '-') {
								tzSign = -1;
							}
							++date;
							
							if(2 == sscanf(date, "%02d:%02d", &tzHour, &tzMinute)) {
								tz = [NSTimeZone timeZoneForSecondsFromGMT:tzSign * (tzHour * 60 * 60 + tzMinute * 60)];
							}
						} else {
							while (*date) {
								if (ISALPHA(*date)) {
									alphaBuf[alphaBufLength++] = *date;
								}
								++date;
							}
						}
						
						if (!tz && alphaBufLength > 0) {
							NSString *tzName = [[NSString alloc] initWithBytes:alphaBuf 
																		length:alphaBufLength 
																	  encoding:NSASCIIStringEncoding];
							
							tz = [NSTimeZone timeZoneWithAbbreviation:tzName];
						}
					}	
				}
			}
		}
				
		if (!tz) {
			tz = [NSTimeZone timeZoneForSecondsFromGMT:0];
		}
		
		NSDateComponents *dc = [[NSDateComponents alloc] init];
		[dc setYear:year];
		[dc setDay:day];
		[dc setMonth:month];
		[dc setHour:hour];
		[dc setMinute:minute];
		[dc setSecond:second];
		[dc setTimeZone:tz];
		
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		result = [calendar dateFromComponents:dc];
		
		
		if (fabsf(millisecond - 0.0f) > 0.01f) {
			result = [result dateByAddingTimeInterval:millisecond];
		}
	}
	
	return result;
}

- (NSString *)gg_RFC3339String {
	static NSDateFormatter *dateFormatter = nil;
	
	if (!dateFormatter) {
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];		
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setCalendar:calendar];
		[dateFormatter setLocale:locale];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
		
	}
	
	return [dateFormatter stringFromDate:self];
}

- (NSString *)gg_RFC2822String {
	static NSDateFormatter *dateFormatter = nil;
	
	if (!dateFormatter) {
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];		
		
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setCalendar:calendar];
		[dateFormatter setLocale:locale];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
		
	}
	
	return [dateFormatter stringFromDate:self];
}

@end