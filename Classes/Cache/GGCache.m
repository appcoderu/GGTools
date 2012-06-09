//
//  GGCache.m
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGCache.h"
#import "GGCacheItem.h"

static const NSUInteger GGCacheDefaultCountLimit = 0;

static NSString * const GGCacheDefaultFolder = @"shared";
static GGCache *sharedInstance = nil;

static const CFDictionaryValueCallBacks dictionaryValuesCallbacks = {0, NULL, NULL, NULL, NULL};

@interface GGCacheItem (Private)
@property(nonatomic, retain) NSString *key;
@end

@implementation GGCache {
	NSString *_dirPath;
	NSUInteger _countLimit;
	
	NSFileManager *fileManager;
	
	CFMutableDictionaryRef cacheItems;
	NSMutableArray *cacheItemsList;
	
#warning use cacheItemsList instead
	NSMutableSet *dirtyCacheItems;
}

+ (GGCache *)sharedCache {
	if (!sharedInstance) {
		sharedInstance = [[[self class] alloc] init];
	}
	
	return [[sharedInstance retain] autorelease];
}

+ (void)setSharedCache:(GGCache *)cache {
	[cache retain];
	[sharedInstance release];
	sharedInstance = cache;
}

#pragma mark -

- (id)init {
	return [self initWithFolder:GGCacheDefaultFolder];
}

- (id)initWithFolder:(NSString *)folder {
	NSString *path = nil;
	
	if (folder) {
		fileManager = [[NSFileManager defaultManager] retain];
		path = [[[[fileManager URLsForDirectory:NSCachesDirectory 
									  inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:folder] path];
	}
		
	return [self initWithPath:path];
}

- (id)initWithPath:(NSString *)path {
	self = [super init];
	if (self) {
        if (!path || [path length] == 0) {
			[self release];
			return nil;
		}
		
		if (!fileManager) {
			fileManager = [[NSFileManager alloc] init];
		}
		
		_countLimit = GGCacheDefaultCountLimit;
		_dirPath = [path retain];
		
		cacheItems = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		cacheItemsList = [[NSMutableArray alloc] initWithCapacity:_countLimit + 10];
		
		[self prepareCacheDirectory:nil];
    }
    return self;
}

- (void)dealloc {
#warning save if dirty?
	[self _clearCacheItems];
	
	CFRelease(cacheItems);
	[cacheItemsList release];
	
	[_dirPath release];
	[fileManager release];
	[dirtyCacheItems release];
	
    [super dealloc];
}

#pragma mark -

- (NSUInteger)countLimit {
	return _countLimit;
}

- (void)setCountLimit:(NSUInteger)countLimit {
	if (countLimit == _countLimit) {
		return;
	}
	
	_countLimit = countLimit;
}

#pragma mark -

- (NSString *)makeValidKey:(NSString *)key {
	if (!key) {
		return nil;
	}
	
	static NSCharacterSet *illegalFileNameCharacters = nil;
	if (!illegalFileNameCharacters) {
		illegalFileNameCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"/:\\?%*|\"<>"] retain];
	}
	
    return [[key componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

- (NSString *)pathForCacheKey:(NSString *)cacheKey {
	cacheKey = [self makeValidKey:cacheKey];
	if (!cacheKey) {
		return nil;
	}
	
	return [_dirPath stringByAppendingPathComponent:cacheKey];
}

- (GGCacheItem *)cachedItemForKey:(NSString *)key {	
	if (!key) {
		return nil;
	}
		
	return [self _cacheItemForKey:key];
}

- (GGCacheItem *)storeData:(NSData *)data withMeta:(NSDictionary *)meta forKey:(NSString *)key {
	if (!data || [data length] == 0) {
		return nil;
	}
	
	GGCacheItem *cacheItem = [self _cacheItemForKey:key];
	
	if (!cacheItem) {
		NSString *path = [self pathForCacheKey:key];
		if (!path) {
			return nil;
		}
		
		cacheItem = [[[GGCacheItem alloc] initWithPath:path] autorelease];
		cacheItem.key = key;
		
		[self _addCacheItem:cacheItem];
	} else {
		[self _bringCacheItemFront:cacheItem];
	}
	
	cacheItem.data = data;
	cacheItem.meta = meta;
	
	return cacheItem;
}

#pragma mark -

- (BOOL)save:(NSError **)error {
	BOOL result = YES;
	
	GGCacheItem *cacheItem = nil;
	while ((cacheItem = [self _nextCacheItemFromDirtyCache])) {
		[cacheItem write];
	}
	
	return result;
}

- (void)clear {
	[self _clearCacheItems];
	[fileManager removeItemAtPath:_dirPath error:nil];
	
	[self prepareCacheDirectory:nil];
}

#pragma mark - Dirty Cache

- (void)_addToDirtyCache:(GGCacheItem *)cacheItem {
	if (!dirtyCacheItems) {
		dirtyCacheItems = [[NSMutableSet alloc] initWithCapacity:10];
	}
	[dirtyCacheItems addObject:cacheItem];
}

- (GGCacheItem *)_nextCacheItemFromDirtyCache {
	if (!dirtyCacheItems) {
		return nil;
	}
	
	GGCacheItem *cacheItem = [dirtyCacheItems anyObject];
	
	if (cacheItem) {
		[[cacheItem retain] autorelease];
		[dirtyCacheItems removeObject:cacheItem];
	}
	
	return cacheItem;
}

#pragma mark - Cache

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self _addToDirtyCache:object];
}

- (void)_addCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	CFDictionarySetValue(cacheItems, cacheItem.key, cacheItem);
	[cacheItemsList addObject:cacheItem];
	
	[cacheItem addObserver:self forKeyPath:@"state" options:0 context:nil];
	
	[self _rotateCache];
}

- (void)_removeCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	[cacheItem removeObserver:self forKeyPath:@"state"];
	
	CFDictionaryRemoveValue(cacheItems, cacheItem.key);
	[cacheItemsList removeObject:cacheItem];
	
#warning check flag?
	[dirtyCacheItems removeObject:cacheItem];
}

- (void)_deleteCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	[cacheItem delete];
	[self _removeCacheItem:cacheItem];
}

- (void)_bringCacheItemFront:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	[cacheItemsList removeObject:cacheItem];
	[cacheItemsList addObject:cacheItem];
}

- (GGCacheItem *)_cacheItemForKey:(NSString *)key {
	GGCacheItem *cacheItem = CFDictionaryGetValue(cacheItems, key);
	return [[cacheItem retain] autorelease];
}

- (void)_clearCacheItems {
	[(NSDictionary *)cacheItems enumerateKeysAndObjectsUsingBlock:^(id key, GGCacheItem *cacheItem, BOOL *stop) {
		[cacheItem removeObserver:self forKeyPath:@"state"];
	}];
	CFDictionaryRemoveAllValues(cacheItems);
	[cacheItemsList removeAllObjects];
	[dirtyCacheItems removeAllObjects];
}

- (void)_sortCacheItems {
	[cacheItemsList sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO]]];
}

- (void)_rotateCache {
	if (_countLimit == 0) {
		return;
	}
	
	while ([cacheItemsList count] > _countLimit) {
		[self _deleteCacheItem:[cacheItemsList objectAtIndex:0]];
	}
}

- (BOOL)prepareCacheDirectory:(NSError **)error {
	if (!_dirPath) {
		return NO;
	}
			
	BOOL isDir = NO;	
	if ([fileManager fileExistsAtPath:_dirPath isDirectory:&isDir]) {
		if (!isDir || ![fileManager isWritableFileAtPath:_dirPath]) {
			return NO;
		}
	} else {
		return [fileManager createDirectoryAtPath:_dirPath 
			 withIntermediateDirectories:YES 
							  attributes:nil 
								   error:error];
	}
	
	[self updateCacheItemsList];
	
	return YES;
}

- (void)updateCacheItemsList {
	[self _clearCacheItems];
	
	NSArray *files = [fileManager contentsOfDirectoryAtPath:_dirPath error:nil];
	if (!files || [files count] == 0) {
		return;
	}
	
	for (NSString *fileName in files) {
#warning replace "meta" with constant
		if ([[fileName pathExtension] isEqualToString:@"meta"]) {
			continue;
		}
		
		NSString *filePath = [_dirPath stringByAppendingPathComponent:fileName];
		
		GGCacheItem *cacheItem = [[GGCacheItem alloc] initWithPath:filePath];
		cacheItem.key = fileName;
		
		[self _addCacheItem:cacheItem];
		
		[cacheItem release];
	}
	
	[self _sortCacheItems];
}

@end
