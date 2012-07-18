//
//  NSString+Crypto.h
//
//  Created by Evgeniy Shurakov on 05.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Crypto)

+ (NSString *)saltWithLength:(NSUInteger)length;

- (NSString *)sha1;
- (NSString *)md5;

@end
