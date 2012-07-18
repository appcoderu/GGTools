//
//  GGCache.m
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGCache.h"
#import "GGCacheItem.h"

static const NSUInteger GGCacheDefaultCountLimit = 30;
static const NSTimeInterval GGCacheSaveDelay = 5.0;

static NSString * const GGCacheDefaultFolder = @"shared";
static NSString * const GGCacheMetaExtension = @"meta";

static GGCache *sharedInstance = nil;

#pragma mark -

@interface GGCacheItemProxy : NSProxy

@property(nonatomic, strong, readonly) GGCacheItem *cacheItem;
@property(nonatomic, strong, readonly) GGCache *cache;

- (id)initWithCacheItem:(GGCacheItem *)aCacheItem cache:(GGCache *)aCache;

@end

#pragma mark -

@interface GGCacheItem (Private)

@property(nonatomic, strong) NSString *key;
@property(nonatomic, weak) id proxy;
@property(nonatomic, assign, readwrite) NSTimeInterval age;

- (BOOL)write;
- (void)delete;

- (void)dehydrate;

@end

#pragma mark -

@implementation GGCache {
	NSString *_dirPath;
	NSUInteger _countLimit;
	
	NSFileManager *fileManager;
	
	CFMutableDictionaryRef cacheItems;
	NSMutableArray *cacheItemsList;
}

+ (GGCache *)sharedCache {
	if (!sharedInstance) {
		sharedInstance = [[[self class] alloc] init];
	}
	
	return sharedInstance;
}

+ (void)setSharedCache:(GGCache *)cache {
	sharedInstance = cache;
}

#pragma mark -

- (id)init {
	return [self initWithFolder:GGCacheDefaultFolder countLimit:GGCacheDefaultCountLimit];
}

- (id)initWithFolder:(NSString *)folder countLimit:(NSUInteger)countLimit {
	NSString *path = nil;
	
	if (folder) {
		fileManager = [NSFileManager defaultManager];
		path = [[[[fileManager URLsForDirectory:NSCachesDirectory 
									  inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:folder] path];
	}
		
	return [self initWithPath:path countLimit:countLimit];
}

- (id)initWithPath:(NSString *)path countLimit:(NSUInteger)countLimit {
	self = [super init];
	if (self) {
        if (!path || [path length] == 0) {
			return nil;
		}
				
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(didReceiveMemoryWarning) 
													 name:UIApplicationDidReceiveMemoryWarningNotification 
												   object:nil];
		
		if (!fileManager) {
			fileManager = [[NSFileManager alloc] init];
		}
		
		_countLimit = countLimit;
		_dirPath = path;
		
		cacheItems = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		cacheItemsList = [[NSMutableArray alloc] initWithCapacity:_countLimit + 10];
		
		[self initCache];
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self save];
	
	[self _clearCacheItems];
	
	CFRelease(cacheItems);
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
	
	[self _rotateCache];
}

#pragma mark -

- (GGCacheItem *)cachedItemForKey:(NSString *)key {	
	key = [self makeValidKey:key];
	if (!key) {
		return nil;
	}
		
	return [self _proxyCacheItem:[self _cacheItemForKey:key]];
}

- (GGCacheItem *)storeData:(NSData *)data withMeta:(NSDictionary *)meta forKey:(NSString *)key {
	if (!data || [data length] == 0) {
		return nil;
	}
	
	key = [self makeValidKey:key];
	
	GGCacheItem *cacheItem = [self _cacheItemForKey:key];
	
	if (!cacheItem) {
		NSString *path = [self pathForCacheKey:key];
		if (!path) {
			return nil;
		}
		
		cacheItem = [[GGCacheItem alloc] initWithPath:path metaExtension:GGCacheMetaExtension];
		cacheItem.key = key;
		
		[self _addCacheItem:cacheItem];
	} else {
		[self _bringCacheItemFront:cacheItem];
	}
	
	cacheItem.data = data;
	cacheItem.meta = meta;
	
	GGCacheItem *_proxy = [self _proxyCacheItem:cacheItem];
	
	[self _rotateCache];
	
	return _proxy;
}

- (void)bumpAgeOfCachedItem:(GGCacheItem *)_cacheItem {
	GGCacheItem *cacheItem = [self _cacheItemForKey:_cacheItem.key];	
	if (!cacheItem) {
		return;
	}
	
	[self _bringCacheItemFront:cacheItem];
	
	cacheItem.age = 0.0;
}

- (void)delayedSave {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(save) object:nil];
	[self performSelector:@selector(save) withObject:nil afterDelay:GGCacheSaveDelay];
}

- (BOOL)save {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(save) object:nil];
	
	for (GGCacheItem *cacheItem in cacheItemsList) {
		if (![cacheItem hasUnsavedChanges]) {
			continue;
		}
		
		if (![cacheItem write]) {
			if ([self isCacheDirectoryExists]) {
				return NO;
			} else if (![self createCacheDirectory]) {
				return NO;
			}
			
			if (![cacheItem write]) {
				return NO;
			}
		}
		
		if (![cacheItem inUse]) {
			[cacheItem dehydrate];
		}
	}
	
	return YES;
}

- (void)clear {
	[self _clearCacheItems];
	[fileManager removeItemAtPath:_dirPath error:nil];
	
	[self initCache];
}

- (NSString *)path {
	return _dirPath;
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	[self save];
}

#pragma mark - Cache

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self delayedSave];
}

- (void)initCache {
	if (!_dirPath) {
		return;
	}
	
	if ([self isCacheDirectoryExists]) {
		if (![self isCacheDirectoryWritable]) {
			return;
		}
	} else if (![self createCacheDirectory]) {
		return;
	}
	
	[self updateCacheItemsList];
	
	return;
}

- (void)updateCacheItemsList {
	[self _clearCacheItems];
	
	NSArray *files = [fileManager contentsOfDirectoryAtPath:_dirPath error:nil];
	if (!files || [files count] == 0) {
		return;
	}
	
	for (NSString *fileName in files) {
		if ([[fileName pathExtension] isEqualToString:GGCacheMetaExtension]) {
			continue;
		}
		
		NSString *filePath = [_dirPath stringByAppendingPathComponent:fileName];
		
		GGCacheItem *cacheItem = [[GGCacheItem alloc] initWithPath:filePath metaExtension:GGCacheMetaExtension];
		cacheItem.key = fileName;
		
		[self _addCacheItem:cacheItem];
		
	}
	
	[self _sortCacheItems];
	
	[self performSelector:@selector(_rotateCache) withObject:nil afterDelay:0.1];
}

- (NSString *)makeValidKey:(NSString *)key {
	if (!key) {
		return nil;
	}
	
	static NSCharacterSet *illegalFileNameCharacters = nil;
	if (!illegalFileNameCharacters) {
		illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/:\\?%*|\"<>"];
	}
	
    return [[key componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
}

- (NSString *)pathForCacheKey:(NSString *)cacheKey {
	if (!cacheKey) {
		return nil;
	}
	
	return [_dirPath stringByAppendingPathComponent:cacheKey];
}

- (BOOL)isCacheDirectoryExists {
	if (!_dirPath) {
		return NO;
	}
	
	BOOL isDir = NO;	
	if ([fileManager fileExistsAtPath:_dirPath isDirectory:&isDir] && isDir) {
		return YES;
	}
	
	return NO;
}

- (BOOL)isCacheDirectoryWritable {
	if (!_dirPath) {
		return NO;
	}
	
	return [fileManager isWritableFileAtPath:_dirPath];
}

- (BOOL)createCacheDirectory {
	if (!_dirPath) {
		return NO;
	}
	
	return [fileManager createDirectoryAtPath:_dirPath 
				  withIntermediateDirectories:YES 
								   attributes:nil 
										error:nil];
}

#pragma mark - Cache utilities

- (GGCacheItem *)_proxyCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return nil;
	}
	
	GGCacheItemProxy *proxy = nil;
	
	if (!cacheItem.proxy) {
		proxy = [[GGCacheItemProxy alloc] initWithCacheItem:cacheItem cache:self];
		cacheItem.proxy = proxy;
	} else {
		proxy = cacheItem.proxy;
	}

	return (GGCacheItem *)proxy;
}

- (void)_removeProxyItem:(GGCacheItemProxy *)proxy {
	if (![proxy.cacheItem hasUnsavedChanges]) {
		[proxy.cacheItem dehydrate];
	}
	
	proxy.cacheItem.proxy = nil;
}

- (void)_addCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	CFDictionarySetValue(cacheItems, (__bridge const void *)(cacheItem.key), (__bridge const void *)(cacheItem));
	[cacheItemsList addObject:cacheItem];
	
	[cacheItem addObserver:self forKeyPath:@"state" options:0 context:nil];
}

- (void)_removeCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	[cacheItem removeObserver:self forKeyPath:@"state"];
	
	CFDictionaryRemoveValue(cacheItems, (__bridge const void *)(cacheItem.key));
	[cacheItemsList removeObject:cacheItem];
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
	if (!key) {
		return nil;
	}
	return (__bridge GGCacheItem *)CFDictionaryGetValue(cacheItems, (__bridge const void *)(key));
}

- (void)_clearCacheItems {
	[(__bridge NSDictionary *)cacheItems enumerateKeysAndObjectsUsingBlock:^(id key, GGCacheItem *cacheItem, BOOL *stop) {
		[cacheItem removeObserver:self forKeyPath:@"state"];
	}];
	CFDictionaryRemoveAllValues(cacheItems);
	[cacheItemsList removeAllObjects];
}

- (void)_sortCacheItems {
	[cacheItemsList sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO]]];
}

- (void)_rotateCache {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_rotateCache) object:nil];
	
	if (_countLimit == 0) {
		return;
	}
	
	NSUInteger skip = 0;
	while ([cacheItemsList count] > _countLimit && skip < [cacheItemsList count]) {
		GGCacheItem *cacheItem = [cacheItemsList objectAtIndex:skip];
		if ([cacheItem inUse]) {
			++skip;
			continue;
		}
		
		[self _deleteCacheItem:cacheItem];
	}
}

@end

@implementation GGCacheItemProxy {
	GGCache *cache;
	GGCacheItem *cacheItem;
}

@synthesize cacheItem, cache;

- (id)initWithCacheItem:(GGCacheItem *)aCacheItem cache:(GGCache *)aCache {
	cacheItem = aCacheItem;
	cache = aCache;

	return self;
}

- (void)dealloc {
	[cache _removeProxyItem:self];
	
	
}

- (id)forwardingTargetForSelector:(SEL)sel {
	return cacheItem; 
}

@end


