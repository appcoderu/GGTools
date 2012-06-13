//
//  GGCache.m
//
//  Created by Evgeniy Shurakov on 16.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGCache.h"
#import "GGCacheItem.h"

static const NSUInteger GGCacheDefaultCountLimit = 0;
static const NSTimeInterval GGCacheSaveDelay = 5.0;

static NSString * const GGCacheDefaultFolder = @"shared";
static NSString * const GGCacheMetaExtension = @"meta";

static GGCache *sharedInstance = nil;

static const CFDictionaryValueCallBacks dictionaryValuesCallbacks = {0, NULL, NULL, NULL, NULL};

#pragma mark -

@interface GGCacheItemProxy : NSProxy

@property(nonatomic, retain, readonly) GGCacheItem *cacheItem;
@property(nonatomic, retain, readonly) GGCache *cache;

- (id)initWithCacheItem:(GGCacheItem *)aCacheItem cache:(GGCache *)aCache;

@end

#pragma mark -

@interface GGCacheItem (Private)

@property(nonatomic, retain) NSString *key;
@property(nonatomic, assign) id proxy;

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
				
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(didReceiveMemoryWarning) 
													 name:UIApplicationDidReceiveMemoryWarningNotification 
												   object:nil];
		
		if (!fileManager) {
			fileManager = [[NSFileManager alloc] init];
		}
		
		_countLimit = GGCacheDefaultCountLimit;
		_dirPath = [path retain];
		
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
	[cacheItemsList release];
	
	[_dirPath release];
	[fileManager release];
	
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
		
		cacheItem = [[[GGCacheItem alloc] initWithPath:path] autorelease];
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
	return [[_dirPath retain] autorelease];
}

#pragma mark -

- (void)didReceiveMemoryWarning {
	[self save];
}

#pragma mark - Cache

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self delayedSave];
}

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
	if (!cacheKey) {
		return nil;
	}
	
	return [_dirPath stringByAppendingPathComponent:cacheKey];
}

- (GGCacheItem *)_proxyCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return nil;
	}
	
	if (!cacheItem.proxy) {
		GGCacheItemProxy *proxy = [[[GGCacheItemProxy alloc] initWithCacheItem:cacheItem cache:self] autorelease];
		cacheItem.proxy = proxy;
	}

	return [[cacheItem.proxy retain] autorelease];
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
	
	CFDictionarySetValue(cacheItems, cacheItem.key, cacheItem);
	[cacheItemsList addObject:cacheItem];
	
	[cacheItem addObserver:self forKeyPath:@"state" options:0 context:nil];
}

- (void)_removeCacheItem:(GGCacheItem *)cacheItem {
	if (!cacheItem) {
		return;
	}
	
	[cacheItem removeObserver:self forKeyPath:@"state"];
	
	CFDictionaryRemoveValue(cacheItems, cacheItem.key);
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
	GGCacheItem *cacheItem = CFDictionaryGetValue(cacheItems, key);
	return [[cacheItem retain] autorelease];
}

- (void)_clearCacheItems {
	[(NSDictionary *)cacheItems enumerateKeysAndObjectsUsingBlock:^(id key, GGCacheItem *cacheItem, BOOL *stop) {
		[cacheItem removeObserver:self forKeyPath:@"state"];
	}];
	CFDictionaryRemoveAllValues(cacheItems);
	[cacheItemsList removeAllObjects];
}

- (void)_sortCacheItems {
	[cacheItemsList sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO]]];
}

- (void)_rotateCache {
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

- (BOOL)initCache {
	if (!_dirPath) {
		return NO;
	}
			
	if ([self isCacheDirectoryExists]) {
		if (![self isCacheDirectoryWritable]) {
			return NO;
		}
	} else if (![self createCacheDirectory]) {
		return NO;
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
		if ([[fileName pathExtension] isEqualToString:GGCacheMetaExtension]) {
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

@implementation GGCacheItemProxy {
	GGCache *cache;
	GGCacheItem *cacheItem;
}

@synthesize cacheItem, cache;

- (id)initWithCacheItem:(GGCacheItem *)aCacheItem cache:(GGCache *)aCache {
	cacheItem = [aCacheItem retain];
	cache = [aCache retain];

	return self;
}

- (void)dealloc {
	[cache _removeProxyItem:self];
	
	[cache release];
	cache = nil;
	
    [cacheItem release];
    [super dealloc];
}

- (id)forwardingTargetForSelector:(SEL)sel {
	return cacheItem; 
}

@end


