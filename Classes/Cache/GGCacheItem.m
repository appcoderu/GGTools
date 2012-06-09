//
//  GGCacheItem.m
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGCacheItem.h"

enum {
	GGCacheItemOK = 0,
	GGCacheItemNeedsWriteMeta = 1 << 0,
	GGCacheItemNeedsWriteData = 1 << 1
};

@interface GGCacheItem ()
@property(nonatomic, retain) NSString *key;
@end

@implementation GGCacheItem {
	NSString *_dataPath;
	NSString *_metaPath;
	
	NSData *_data;
	NSMutableDictionary *_meta;

	unsigned int state;
}

@synthesize data=_data;
@synthesize key=_key;

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return NO;
}

- (id)init {
	return [self initWithPath:nil];
}

- (id)initWithPath:(NSString *)path {
	self = [super init];
	if (self) {
		if (!path || [path length] == 0) {
			[self release];
			return nil;
		}
		
		_dataPath = [path retain];
#warning replace "meta" with constant
		_metaPath = [[_dataPath stringByAppendingPathExtension:@"meta"] retain];
	}
	return self;
}

- (void)dealloc {
	[_key release];
    [_dataPath release];
	[_metaPath release];
	[_data release];
	[_meta release];
	
    [super dealloc];
}

#pragma mark -

- (void)write {
	if ((state & GGCacheItemNeedsWriteData)) {
		state &= ~GGCacheItemNeedsWriteData;
		[_data writeToFile:_dataPath atomically:YES];
	}
	
	if ((state & GGCacheItemNeedsWriteMeta)) {
		state &= ~GGCacheItemNeedsWriteMeta;
		if (_meta && [_meta count] > 0) {
			[_meta writeToFile:_metaPath atomically:YES];
		} else {
			[[NSFileManager defaultManager] removeItemAtPath:_metaPath error:nil];
		}
	}
}

- (void)delete {
	[[NSFileManager defaultManager] removeItemAtPath:_dataPath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:_metaPath error:nil];
}

#pragma mark -

- (NSData *)data {
	if (!_data) {
		_data = [[NSData alloc] initWithContentsOfFile:_dataPath];
	}
	
	return [[_data retain] autorelease];
}

- (void)setData:(NSData *)data {
	if (data == _data || (data && _data && [data isEqualToData:_data])) {
		return;
	}
	
	[data retain];
	[_data release];
	_data = data;
	
	[self setNeedsWriteData];
}

- (NSTimeInterval)age {
#warning cache modification time?
	
	if ([self exists]) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSDictionary *fileAttrs = [fm attributesOfItemAtPath:_dataPath error:NULL];
		NSDate *modificationDate = [fileAttrs objectForKey:NSFileModificationDate];
		
		return -[modificationDate timeIntervalSinceNow];
	} else {
		return DBL_MAX;
	}
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
	
	state |= GGCacheItemNeedsWriteMeta;
	
	[self willChangeValueForKey:@"state"];
	state |= GGCacheItemNeedsWriteData;
	[self didChangeValueForKey:@"state"];
}

- (void)setNeedsWriteData {
	if ((state & GGCacheItemNeedsWriteData)) {
		return;
	}
	
	[self willChangeValueForKey:@"state"];
	state |= GGCacheItemNeedsWriteData;
	[self didChangeValueForKey:@"state"];
}

- (NSMutableDictionary *)_meta {
	if (!_meta) {
		_meta = [[NSMutableDictionary alloc] initWithContentsOfFile:_metaPath];
		if (!_meta) {
			_meta = [[NSMutableDictionary alloc] initWithCapacity:10];
		}
	}
	
	return [[_meta retain] autorelease];
}

@end
