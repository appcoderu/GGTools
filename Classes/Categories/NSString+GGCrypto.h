//
//  NSString+Crypto.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 05.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (GGCrypto)

+ (NSString *)gg_saltWithLength:(NSUInteger)length;

- (NSString *)gg_sha1;
- (NSString *)gg_md5;

@end
