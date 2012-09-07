//
//  GGCacheItem.m
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGCacheItem.h"

enum {
	GGCacheItemOK = 0U,
	GGCacheItemNeedsWriteMeta = 1U << 0,
	GGCacheItemNeedsWriteData = 1U << 1
};

@interface GGCacheItem ()
@property(nonatomic, strong) NSString *key;
@property(nonatomic, assign) id proxy;
@end

@implementation GGCacheItem {
	NSString *_dataPath;
	NSString *_metaPath;
	
	NSData *_data;
	NSMutableDictionary *_meta;
	
	NSDate *_modificationDate;
	
	unsigned int state;
	
	// Due to ARC bug this is not weak
	__unsafe_unretained id _proxy;
}

@synthesize data=_data;
@synthesize key=_key;
@synthesize proxy=_proxy;

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return NO;
}

- (id)init {
	return [self initWithPath:nil metaExtension:nil];
}

- (id)initWithPath:(NSString *)path metaExtension:(NSString *)metaExtension {
	self = [super init];
	if (self) {
		if (!path || [path length] == 0) {
			return nil;
		}
		
		_dataPath = path;
		
		if (metaExtension && [metaExtension length] > 0) {
			_metaPath = [_dataPath stringByAppendingPathExtension:metaExtension];
		}
	}
	return self;
}

- (void)dealloc {
	_proxy = nil;
}

#pragma mark -

- (BOOL)write {
	if ((state & GGCacheItemNeedsWriteData)) {
		state &= ~GGCacheItemNeedsWriteData;
		if (![_data writeToFile:_dataPath atomically:YES]) {
			state |= GGCacheItemNeedsWriteData;
			return NO;
		}
		
		_modificationDate = nil;
	}
	
	if ((state & GGCacheItemNeedsWriteMeta)) {
		state &= ~GGCacheItemNeedsWriteMeta;
		
		if (_metaPath) {
			if (_meta && [_meta count] > 0) {
				if (![_meta writeToFile:_metaPath atomically:YES]) {
					state |= GGCacheItemNeedsWriteMeta;
					return NO;
				}
			} else {
				if (![[NSFileManager defaultManager] removeItemAtPath:_metaPath error:nil]) {
					state |= GGCacheItemNeedsWriteMeta;
					return NO;
				}
			}
		}
	}
	return YES;
}

- (void)delete {
	[[NSFileManager defaultManager] removeItemAtPath:_dataPath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:_metaPath error:nil];
	
	_modificationDate = nil;
}

- (BOOL)hasUnsavedChanges {
	return (state != GGCacheItemOK);
}

- (BOOL)inUse {
	return (_proxy != nil);
}

#pragma mark -

- (void)dehydrate {
	state = GGCacheItemOK;
	
	_data = nil;
	
	_meta = nil;
}

- (NSData *)data {
	if (!_data) {
		_data = [[NSData alloc] initWithContentsOfFile:_dataPath];
	}
	
	return _data;
}

- (void)setData:(NSData *)data {
	if (data == _data || (data && _data && [data isEqualToData:_data])) {
		return;
	}
	
	_data = data;
	
	[self setNeedsWriteData];
}

- (NSTimeInterval)age {	
	if ([self exists]) {
		if (!_modificationDate) {
			NSFileManager *fm = [NSFileManager defaultManager];
			NSDictionary *fileAttrs = [fm attributesOfItemAtPath:_dataPath error:NULL];
			_modificationDate = [fileAttrs objectForKey:NSFileModificationDate];
		}
				
		return -[_modificationDate timeIntervalSinceNow];
	} else {
		return DBL_MAX;
	}
}

- (void)setAge:(NSTimeInterval)age {
	if (![self exists]) {
		return;
	}
	
	_modificationDate = [NSDate dateWithTimeIntervalSinceNow:-age];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableDictionary *fileAttrs = [[NSMutableDictionary alloc] initWithObjectsAndKeys:_modificationDate, NSFileModificationDate, nil];
	
	[fm setAttributes:fileAttrs 
		 ofItemAtPath:_dataPath 
				error:nil];
	
}

- (BOOL)exists {
	return [[NSFileManager defaultManager] fileExistsAtPath:_dataPath];
}

- (NSDictionary *)meta {
	return [self _meta];
}

- (void)setMeta:(NSDictionary *)meta {
	if (meta) {
		[[self _meta] setDictionary:meta];
	} else if (_meta) {
		[_meta removeAllObjects];
	} else {
		return;
	}
	
	[self setNeedsWriteMeta];
}

- (id)metaValueForKey:(NSString *)key {
	return [[self _meta] objectForKey:key];
}

- (void)setMetaValue:(id)value forKey:(NSString *)key {
	if (!key) {
		return;
	}
	
	if (value) {
		[[self _meta] setObject:value forKey:key];
	} else {
		[[self _meta] removeObjectForKey:key];
	}
	
	[self setNeedsWriteMeta];
}

#pragma mark -

- (void)setNeedsWriteMeta {
	if ((state & GGCacheItemNeedsWriteMeta)) {
		return;
	}
		
	if (state == GGCacheItemOK) {
		[self willChangeValueForKey:@"state"];
		state |= GGCacheItemNeedsWriteMeta;
		[self didChangeValueForKey:@"state"];
	} else {
		state |= GGCacheItemNeedsWriteMeta;
	}
	
}

- (void)setNeedsWriteData {
	if ((state & GGCacheItemNeedsWriteData)) {
		return;
	}
	
	if (state == GGCacheItemOK) {
		[self willChangeValueForKey:@"state"];
		state |= GGCacheItemNeedsWriteData;
		[self didChangeValueForKey:@"state"];
	} else {
		state |= GGCacheItemNeedsWriteData;
	}
}

- (NSMutableDictionary *)_meta {
	if (!_meta && _metaPath) {
		_meta = [[NSMutableDictionary alloc] initWithContentsOfFile:_metaPath];
		if (!_meta) {
			_meta = [[NSMutableDictionary alloc] initWithCapacity:10];
		}
	}
	
	return _meta;
}

@end
