//
//  NSString+Crypto.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "NSString+GGCrypto.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (GGCrypto)

+ (NSString *)gg_saltWithLength:(NSUInteger)length {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        srand(time(NULL));
    });
	
    char salt[length];
    for (int i=0; i < length; ++i) {
        salt[i] = (rand() % (126 - 32 + 1) + 32);
    }
	
	return [[NSString alloc] initWithBytes:salt length:length encoding:NSASCIIStringEncoding];
}

- (NSString *)gg_sha1 {
	unsigned char sha1[CC_SHA1_DIGEST_LENGTH];
	const char *str = [self UTF8String];
	CC_SHA1(str, strlen(str), sha1);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
		[output appendFormat:@"%02x", sha1[i]];
	}

	return output;
}

- (NSString *)gg_md5 {
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
	const char *cStr = [self UTF8String];
    CC_MD5( cStr, strlen(cStr), md5 );
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
		[output appendFormat:@"%02x", md5[i]];
	}
	
	return output;
}

@end
