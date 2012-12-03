//
//  GGCacheItem.h
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGCacheItem : NSObject

- (id)initWithPath:(NSString *)path;

@property(nonatomic, readonly) BOOL exists;
@property(nonatomic, readonly) NSTimeInterval age;

@property(nonatomic, strong) NSData *data;
@property(nonatomic, strong) NSDictionary *meta;

- (id)metaValueForKey:(NSString *)key;
- (void)setMetaValue:(id)value forKey:(NSString *)key;

- (BOOL)hasUnsavedChanges;
- (BOOL)inUse;

@end
