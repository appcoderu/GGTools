//
//  GGHTTPService.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPService.h"

#import "GGHTTPServiceInternalTicket.h"
#import "GGHTTPServiceTicket.h"
#import "GGHTTPServiceTicket+Private.h"

#import "GGHTTPConstants.h"

#import "GGHTTPQuery.h"
#import "GGHTTPQueryResult.h"

#import "GGHTTPQueryBody.h"
#import "GGHTTPQueryBodyEncoder.h"

#import "GGHTTPCache.h"
#import "GGHTTPCacheItem.h"

#import "GGHTTPFetcherDelegate.h"
#import "GGHTTPFetcherProtocol.h"

#import "GGHTTPAuthorizationProtocol.h"
#import "GGHTTPCacheProtocol.h"

#import "GGNetworkActivityIndicator.h"

#import "UIDevice+GGUUID.h"
#import "NSError+GGExtra.h"
#import "NSDate+GGExtra.h"
#import "NSString+GGEscape.h"
#import "NSDictionary+GGURL.h"
#import "NSURL+GGQueryParameters.h"

#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kFetcherTicketKey = @"__ticket";

static NSTimeInterval const kGGHTTPServiceDefaultTimeout = 30.0;
static Class GGHTTPServiceFetcherClass = nil;

static unsigned int debug = 0U;
enum {
	GGHTTPServiceDebugRequests			= 1U << 1,
	GGHTTPServiceDebugHeaders			= 1U << 2,
	GGHTTPServiceDebugRequestBody		= 1U << 3,
	GGHTTPServiceDebugRequestRawBody	= 1U << 4,
	GGHTTPServiceDebugResponseBody		= 1U << 5,
	GGHTTPServiceDebugResponseRawBody	= 1U << 6
};

@interface GGHTTPService () <GGHTTPFetcherDelegate>

@end

@implementation GGHTTPService {
	NSMutableSet *_tickets;
	NSMutableDictionary *_httpHeaders;
}

@synthesize baseURL=_baseURL;

@synthesize cache=_cache;
@synthesize persistentCache=_persistentCache;

@synthesize authorizer=_authorizer;

#pragma mark -

+ (void)initialize {
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		
	if ([ud boolForKey:@"ru.appcode.http.debugHeaders"]) {
		debug |= GGHTTPServiceDebugHeaders;
	}
	
	if ([ud boolForKey:@"ru.appcode.http.debugRequestBody"]) {
		debug |= GGHTTPServiceDebugRequestBody;
	}
	
	if ([ud boolForKey:@"ru.appcode.http.debugRequestRawBody"]) {
		debug |= GGHTTPServiceDebugRequestRawBody;
	}
	
	if ([ud boolForKey:@"ru.appcode.http.debugResponseBody"]) {
		debug |= GGHTTPServiceDebugResponseBody;
	}
	
	if ([ud boolForKey:@"ru.appcode.http.debugResponseRawBody"]) {
		debug |= GGHTTPServiceDebugResponseRawBody;
	}
	
	if ((debug && !(debug & GGHTTPServiceDebugRequests)) || [ud boolForKey:@"ru.appcode.http.debug"]) {
		debug |= GGHTTPServiceDebugRequests;
	}
}

+ (id)sharedService {
	static GGHTTPService *sharedInstance = nil;
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		sharedInstance = [[self alloc] init];
		sharedInstance.cache = [GGHTTPCache sharedCache];
	});
	
	return sharedInstance;
}

+ (Class)fetcherClass {
	if (!GGHTTPServiceFetcherClass) {
		GGHTTPServiceFetcherClass = NSClassFromString(@"GGHTTPGoogleFetcher");
	}
	
	return GGHTTPServiceFetcherClass;
}

+ (void)setFetcherClass:(Class)fetcherClass {
	if (fetcherClass && !class_conformsToProtocol(fetcherClass, @protocol(GGHTTPFetcherProtocol))) {
		return;
	}
	
	GGHTTPServiceFetcherClass = fetcherClass;
}

+ (NSString *)GTMCleanedUserAgentString:(NSString *)str {
	// Reference http://www.w3.org/Protocols/rfc2616/rfc2616-sec2.html
	// and http://www-archive.mozilla.org/build/user-agent-strings.html
	
	if (str == nil) return nil;
	
	NSMutableString *result = [NSMutableString stringWithString:str];
	
	// Replace spaces with underscores
	[result replaceOccurrencesOfString:@" "
							withString:@"_"
							   options:0
								 range:NSMakeRange(0, [result length])];
	
	// Delete http token separators and remaining whitespace
	static NSCharacterSet *charsToDelete = nil;
	if (charsToDelete == nil) {
		// Make a set of unwanted characters
		NSString *const kSeparators = @"()<>@,;:\\\"/[]?={}";
		
		NSMutableCharacterSet *mutableChars;
		mutableChars = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[mutableChars addCharactersInString:kSeparators];
		charsToDelete = [mutableChars copy]; // hang on to an immutable copy
	}
	
	while (1) {
		NSRange separatorRange = [result rangeOfCharacterFromSet:charsToDelete];
		if (separatorRange.location == NSNotFound) break;
		
		[result deleteCharactersInRange:separatorRange];
	};
	
	return result;
}


#pragma mark -

- (id)init {
    return [self initWithBaseURL:nil];
}

- (id)initWithBaseURL:(NSURL *)baseURL {
	self = [super init];
    if (self) {
        _baseURL = baseURL;
		_tickets = [[NSMutableSet alloc] initWithCapacity:50];
		
		[self setHTTPHeader:self.userAgent forKey:@"User-Agent"];
		[self setHTTPHeader:@"gzip" forKey:@"Accept-Encoding"];
		[self setHTTPHeader:[[UIDevice currentDevice] gg_UUID] forKey:@"X-Device-ID"];
    }
    return self;
}

#pragma mark -

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			   completionHandler:(GGHTTPServiceCompletionHandler)handler {
	return [self executeQuery:[GGHTTPQuery queryWithURL:url]
			completionHandler:handler];
}

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
   completionHandler:(GGHTTPServiceCompletionHandler)handler {
	if (!query) {
		if (handler) {
			NSError *error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil) 
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			
			handler(nil, [GGHTTPQueryResult queryResultWithError:error]);
		}
		return nil;
	}
	

	GGHTTPServiceInternalTicket *internalTicket = [self ticketForQuery:query];
	if (internalTicket) {
		GGHTTPServiceTicket *ticket = [[GGHTTPServiceTicket alloc] init];
		ticket.query = query;
		ticket.completionHandler = handler;
		
		[internalTicket addClientTicket:ticket];
		
		return ticket;
	}
	
	
	GGHTTPCacheItem *cacheItem = [self cacheForQuery:query];
	if (cacheItem) {
		BOOL useCachedItem = NO;
		
		if (query.revalidateInterval > 0.01) {
			if (cacheItem.age < query.revalidateInterval) {
				useCachedItem = YES;
			}
		} else if ([cacheItem canBeUsedWithoutRevalidation]) {
			useCachedItem = YES;
		}
		
		if (useCachedItem) {
			
			if (debug & GGHTTPServiceDebugRequests) {
				NSLog(@"Use cached item for %@", [self URLForQuery:query]);
			}
			
			GGHTTPServiceTicket *ticket = [[GGHTTPServiceTicket alloc] init];
			ticket.query = query;
			ticket.used = YES;
			
			if (handler) {
				GGHTTPQueryResult *result = [[GGHTTPQueryResult alloc] init];
				result.cacheItem = cacheItem;
				result.query = query;
				
				handler(ticket, result);
			}
			
			return ticket;
		}
	}
	
	NSMutableURLRequest *request = [self requestForQuery:query];
	if (!request) {
		if (handler) {
			NSError *error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil) 
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, [GGHTTPQueryResult queryResultWithError:error]);
		}
		return nil;
	}
	
	if (debug & GGHTTPServiceDebugRequests) {
		NSLog(@"%@: %@", [request HTTPMethod], [request URL]);
	}
	
	if (cacheItem) {		
		if (debug & GGHTTPServiceDebugRequests) {
			NSLog(@"Revalidate cached item for %@", [request URL]);
		}

		NSString *lastModified = cacheItem.lastModified;
		NSString *eTag = cacheItem.eTag;
		
		if (eTag) {
			[request setValue:eTag forHTTPHeaderField:@"If-None-Match"];
		}
		
		if (lastModified) {
			[request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
		}
	}
	
	if (debug & GGHTTPServiceDebugHeaders) {
		NSLog(@"%@", [request allHTTPHeaderFields]);
	}
	
	if ((debug & GGHTTPServiceDebugRequestBody) && query.bodyObject) {
		NSLog(@"%@", query.bodyObject);
	}
	
	if ((debug & GGHTTPServiceDebugRequestRawBody) && [request HTTPBody]) {
		NSLog(@"%@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
	}
		
	NSObject <GGHTTPFetcherProtocol> *fetcher = [self fetcherWithRequest:request];
	if (!fetcher) {
		if (handler) {
			NSError *error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil)
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, [GGHTTPQueryResult queryResultWithError:error]);
		}
		return nil;
	}
	
	if (!query.suppressAuthorization) {
		fetcher.authorizer = self.authorizer;
	}

	fetcher.retryEnabled = YES;
	fetcher.maxRetryInterval = 15.0;
	
	internalTicket = [GGHTTPServiceInternalTicket ticketWithQuery:query];
	internalTicket.fetcher = fetcher;
	internalTicket.cachedItem = cacheItem;
	
	GGHTTPServiceTicket *ticket = [[GGHTTPServiceTicket alloc] init];
	ticket.query = query;
	ticket.completionHandler = handler;
	
	[internalTicket addClientTicket:ticket];
	
	[fetcher setProperty:internalTicket forKey:kFetcherTicketKey];

	[GGNetworkActivityIndicator show];
	
	BOOL didFetch = [fetcher beginFetchWithDelegate:self];
	
	if (!didFetch || internalTicket.used) {
		if (!internalTicket.used) {
			[GGNetworkActivityIndicator hide];
		}
		
		internalTicket.fetcher = nil;
		internalTicket.cachedItem = nil;
		[internalTicket removeAllClientTickets];
		
		fetcher.properties = nil;
		
		return nil;
	}
	
	[_tickets addObject:internalTicket];
	
	return ticket;
}

- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key {
	if (!key) {
		return;
	}
	
	if (parameter) {
		if (!_httpHeaders) {
			_httpHeaders = [[NSMutableDictionary alloc] initWithCapacity:1];
		}
		[_httpHeaders setObject:parameter forKey:key];
	} else {
		[_httpHeaders removeObjectForKey:key];
	}
}

#pragma mark - Tickets

- (GGHTTPServiceInternalTicket *)ticketForQuery:(GGHTTPQuery *)query {
	if (!query) {
		return nil;
	}
	
	if (query.httpMethod && ![query.httpMethod isEqualToString:GGHTTPMethodGET]) {
		return nil;
	}
	
	NSURL *url = [self URLForQuery:query];
	if (!url) {
		return nil;
	}
	
	for (GGHTTPServiceInternalTicket *ticket in _tickets) {
		if (ticket.query.httpMethod && ![ticket.query.httpMethod isEqualToString:GGHTTPMethodGET]) {
			continue;
		}
		
		if ([[ticket.fetcher.mutableRequest URL] isEqual:url]) {
			return ticket;
		}
	}
	
	return nil;
}

- (GGHTTPServiceInternalTicket *)ticketForClientTicket:(GGHTTPServiceTicket *)clientTicket {
	return clientTicket.internalTicket;
}

- (void)cancelQueryWithTicket:(GGHTTPServiceTicket *)clientTicket {
	GGHTTPServiceInternalTicket *ticket = [self ticketForClientTicket:clientTicket];
	if (!ticket || ticket.used || !ticket.fetcher) {
		return;
	}
	
	clientTicket.used = YES;
	clientTicket.internalTicket = nil;
	
	[ticket removeClientTicket:clientTicket];
	
	if (ticket.clientTickets.count > 0) {
		return;
	}
	
	[ticket.fetcher stopFetching];
	ticket.fetcher.properties = nil;
	ticket.fetcher = nil;
	
	ticket.cachedItem = nil;
	
	[_tickets removeObject:ticket];
	
	[GGNetworkActivityIndicator hide];
}

#pragma mark -

- (NSObject <GGHTTPFetcherProtocol> *)fetcherWithRequest:(NSMutableURLRequest *)request {
	return [[[self class] fetcherClass] fetcherWithRequest:request];
}

#pragma mark - Construct Request

- (NSMutableURLRequest *)requestForQuery:(GGHTTPQuery *)query {
	if (!query) {
		return nil;
	}
	
	NSURL *url = [self requestURLForQuery:query];
	if (!url) {
		return nil;
	}
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
																cachePolicy:NSURLRequestReloadIgnoringCacheData
															timeoutInterval:query.timeout > 0.1 ? query.timeout : kGGHTTPServiceDefaultTimeout];
	
	if (!query.httpMethod || [query.httpMethod length] == 0)  {
		query.httpMethod = GGHTTPMethodGET;
	}
	request.HTTPMethod = query.httpMethod;
	
	NSError *error = nil;
	GGHTTPQueryBody *body = [self requestBodyForQuery:query error:&error];
	
	if (error) {
		return nil;
	}
	
	if (body) {
		request.HTTPBody = [body data];
		NSString *httpBodyLength = [NSString stringWithFormat:@"%d", [[body data] length]];
		[request setValue:httpBodyLength forHTTPHeaderField:@"Content-Length"];
				
		if ([body contentType]) {
			[request setValue:[body contentType] forHTTPHeaderField:@"Content-Type"];
		}
	}
	
	id enumerationBlock = ^(id key, id obj, BOOL *stop) {
		[request setValue:obj forHTTPHeaderField:key];
	};
	
	[_httpHeaders enumerateKeysAndObjectsUsingBlock:enumerationBlock];
	[query.httpHeaders enumerateKeysAndObjectsUsingBlock:enumerationBlock];
		
	return request;
}

- (NSURL *)URLForQuery:(GGHTTPQuery *)query {
	NSURL *result = nil;
	
	if (query.url) {
		result = query.url;
	} else if (query.relativePath) {
		if (!query.queryPathComponents || [query.queryPathComponents count] == 0) {
			result = [NSURL URLWithString:query.relativePath relativeToURL:self.baseURL];
		} else {
			NSMutableArray *pathComponents = [[NSMutableArray alloc] initWithCapacity:1 + [query.queryPathComponents count]];
			[pathComponents addObject:query.relativePath];
			
			for (NSString *pathComponent in query.queryPathComponents) {
				[pathComponents addObject:[NSString gg_stringByURLEncodingForURI:pathComponent]];
			}
			
			result = [NSURL URLWithString:[pathComponents componentsJoinedByString:@"/"] relativeToURL:self.baseURL];
			
		}
		
		query.url = result;
	}
	
	if (query.queryParameters) {
		result = [result gg_URLByAddingQueryParams:query.queryParameters];
	}
		
	return result;
}

- (NSURL *)requestURLForQuery:(GGHTTPQuery *)query {
	return [self URLForQuery:query];
}

- (GGHTTPQueryBody *)requestBodyForQuery:(GGHTTPQuery *)query error:(NSError **)error {
	if (!query.bodyObject) {
		return nil;
	}
	
	if (!query.bodyEncoder) {
		if (error) {
			*error = [NSError gg_errorWithDomain:kGGHTTPServiceErrorDomain
										 code:kGGHTTPServiceErrorInvalidRequestBody
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}

	return [query.bodyEncoder encode:query.bodyObject error:error];
}

#pragma mark -

- (NSObject <GGHTTPCacheProtocol> *)cacheEngineForQuery:(GGHTTPQuery *)query {
	if (query.cachePersistently && self.persistentCache) {
		return self.persistentCache;
	} else {
		return self.cache;
	}
}

- (GGHTTPCacheItem *)cacheForQuery:(GGHTTPQuery *)query {
	if (![self canCacheQuery:query]) {
		return nil;
	}
	return [[self cacheEngineForQuery:query] cachedItemForURL:[self URLForQuery:query]];
}

- (BOOL)canCacheQuery:(GGHTTPQuery *)query {
	if (query &&
		(!query.httpMethod ||
		 (query.httpMethod && [query.httpMethod caseInsensitiveCompare:GGHTTPMethodGET] == NSOrderedSame))) {
		return YES;
	}
	
	return NO;
}

#pragma mark -

- (NSString *)userAgent {		
	NSBundle *bundle = [NSBundle mainBundle];
	
	NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
	if (!appName) {
		appName = @"Unknown Application";
	}
	
	NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (!version) {
		version = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
	
	appName = [[self class] GTMCleanedUserAgentString:appName];
	
	NSMutableArray *userAgentComponents = [NSMutableArray arrayWithCapacity:3];
	
	UIDevice *device = [UIDevice currentDevice];
	
	if (device.systemName) {
		[userAgentComponents addObject:device.systemName];
	}
	
	if (device.model) {
		[userAgentComponents addObject:device.model];
	}
	
	if (device.systemVersion) {
		[userAgentComponents addObject:device.systemVersion];
	}
	
	return [NSString stringWithFormat:@"%@/%@ (%@)", appName, version, [userAgentComponents componentsJoinedByString:@"; "]];
}

#pragma mark - Fetcher callback

- (void)fetcher:(NSObject <GGHTTPFetcherProtocol> *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
	
	if (debug & GGHTTPServiceDebugRequests) {
		NSLog(@"%d: %@", [fetcher statusCode], [[fetcher mutableRequest] URL]);
	}
	
	if (debug & GGHTTPServiceDebugHeaders) {
		NSURLResponse *response = [fetcher response];
		if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
			NSLog(@"%@", [(NSHTTPURLResponse *)response allHeaderFields]);
		}
	}
	
	if (debug & GGHTTPServiceDebugResponseRawBody) {
		NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	}
	
	[GGNetworkActivityIndicator hide];
	
	GGHTTPServiceInternalTicket *ticket = [fetcher propertyForKey:kFetcherTicketKey];
	if (!ticket) {
		return;
	}
	
	ticket.fetcher.properties = nil;
	ticket.fetcher = nil;
	
	ticket.used = YES;
	
	if (data && [data length] == 0) {
		data = nil;
	}
	
	GGHTTPCacheItem *cacheItem = ticket.cachedItem;
	
	GGHTTPQueryResult *queryResult = [[GGHTTPQueryResult alloc] init];
	queryResult.query = ticket.query;
	queryResult.statusCode = [fetcher statusCode];
	
	NSHTTPURLResponse *response = nil;
	
	if ([fetcher.response isKindOfClass:[NSHTTPURLResponse class]]) {
		response = (NSHTTPURLResponse *)(fetcher.response);
	}
		
	if ([fetcher statusCode] == kGGHTTPFetcherStatusNotModified && cacheItem) {
		[[self cacheEngineForQuery:ticket.query] bumpAgeOfCachedItem:cacheItem];
		
		queryResult.cacheItem = cacheItem;
		error = nil;
	} else if (!error && [fetcher statusCode] >= 300) {
		error = [NSError gg_errorWithDomain:kGGHTTPFetcherStatusDomain
									code:[fetcher statusCode]
							 description:nil
						   failureReason:nil];
	} else if (!error && [self canCacheQuery:ticket.query]) {
		[[self cacheEngineForQuery:ticket.query] storeData:data
												   headers:[(NSHTTPURLResponse *)response allHeaderFields]
													forURL:[self URLForQuery:ticket.query]];
	}

	if (!queryResult.cached) {
		queryResult.rawData = data;
		queryResult.responseHeaders = response.allHeaderFields;
		
		if (debug & GGHTTPServiceDebugResponseBody) {
			NSLog(@"%@", queryResult.data);
		}
	}
	
	queryResult.error = error;
	
	for (GGHTTPServiceTicket *clientTicket in ticket.clientTickets) {
		clientTicket.used = YES;
		if (clientTicket.completionHandler) {
			((GGHTTPServiceCompletionHandler)clientTicket.completionHandler)(clientTicket, queryResult);
		}
	}
	
	ticket.cachedItem = nil;
	[ticket removeAllClientTickets];
	
	[_tickets removeObject:ticket];
}


@end
