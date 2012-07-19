//
//  GGHTTPService.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"

#import "GGHTTPConstants.h"

#import "GGHTTPQuery.h"
#import "GGHTTPQueryBody.h"

#import "GGHTTPQueryBodyDecoder.h"
#import "GGHTTPQueryBodyEncoder.h"
#import "GGHTTPQueryBodyJSONTransformer.h"

#import "GGHTTPCache.h"
#import "GGHTTPCacheItem.h"

#import "GGHTTPFetcherDelegate.h"
#import "GGHTTPFetcherProtocol.h"

#import "GGHTTPAuthorizationProtocol.h"
#import "GGHTTPCacheProtocol.h"

#import "UIDevice+UUID.h"
#import "NSError+Extra.h"
#import "NSDate+Extra.h"
#import "NSString+Escape.h"
#import "NSDictionary+URL.h"
#import "NSURL+QueryParameters.h"

#import <objc/runtime.h>
#import <objc/message.h>

NSString * const kGGHTTPServiceErrorDomain				= @"ru.appcode.httpService.error";

static NSString * const kFetcherTicketKey					= @"ticket";
static NSString * const kFetcherCompletionHandlerKey	= @"completionHandler";
static NSString * const kFetcherCacheItemKey				= @"cacheItem";

static NSTimeInterval const kGGHTTPServiceDefaultTimeout = 30.0;
static Class GGHTTPServiceFetcherClass = nil;

@interface GGHTTPService () <GGHTTPFetcherDelegate>

@end

@implementation GGHTTPService {

}

@synthesize userAgent=_userAgent;
@synthesize baseURL=_baseURL;
@synthesize additionalHTTPHeaders=_additionalHTTPHeaders;

@synthesize cache=_cache;
@synthesize persistentCache=_persistentCache;

@synthesize authorizer=_authorizer;

#pragma mark -

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
    }
    return self;
}

#pragma mark -

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	return [self loadURL:url revalidateInterval:0.0 completionHandler:handler];
}

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			  revalidateInterval:(NSTimeInterval)revalidateInterval
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	GGHTTPQuery *query = [GGHTTPQuery queryForURL:url revalidateInterval:revalidateInterval];
	return [self executeQuery:query completionHandler:handler];
}

- (GGHTTPServiceTicket *)executeQuery:(GGHTTPQuery *)query
   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	if (!query) {
		if (handler) {
			NSError *error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil) 
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, nil, error);
		}
		return nil;
	}
		
	NSMutableURLRequest *request = [self requestForQuery:query];
	if (!request) {
		if (handler) {
			NSError *error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil) 
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, nil, error);
		}
		return nil;
	}
	
#if DEBUG_HTTP_SERVICE
	GGLog(@"%@: %@", [request HTTPMethod], [request URL]);
#endif
		
	GGHTTPCacheItem *cacheItem = [[self cacheForQuery:query] cachedItemForRequest:request];
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
#if DEBUG_HTTP_SERVICE
			GGLog(@"Use cached item", nil);
#endif
			if (handler) {
				handler(nil, cacheItem, nil);
			}
			return nil;
		}
		
#if DEBUG_HTTP_SERVICE
		GGLog(@"Validate cached item", nil);
#endif
		NSString *lastModified = cacheItem.lastModified;
		NSString *eTag = cacheItem.eTag;
		
		if (eTag) {
			[request setValue:eTag forHTTPHeaderField:@"If-None-Match"];
		}
		
		if (lastModified) {
			[request setValue:lastModified forHTTPHeaderField:@"If-Modified-Since"];
		}
	}
	
#if DEBUG_HTTP_SERVICE && DEBUG_HTTP_SERVICE_HEADERS
	GGLog(@"%@", [request allHTTPHeaderFields]);
#endif
	
#if DEBUG_HTTP_SERVICE && DEBUG_HTTP_SERVICE_BODY
	if ([request HTTPBody]) {
		GGLog(@"%@", [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
	}
#endif	
	
	NSObject <GGHTTPFetcherProtocol> *fetcher = [self fetcherWithRequest:request];
	if (!fetcher) {
		if (handler) {
			NSError *error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
												 code:kGGHTTPServiceErrorUnableToConstructRequest
										  description:NSLocalizedString(@"Error", nil)
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, nil, error);
		}
		return nil;
	}
	
	//[fetcher setCookieStorageMethod:kGTMHTTPFetcherCookieStorageMethodNone];
	
	if (!query.suppressAuthorization) {
		fetcher.authorizer = self.authorizer;
	}
	
	//fetcher.retryEnabled = YES;
	//fetcher.maxRetryInterval = 15.0;
	
	GGHTTPServiceTicket *ticket = [[GGHTTPServiceTicket alloc] init];
	ticket.query = query;
	ticket.fetcher = fetcher;
	ticket.cacheItem = cacheItem;
	
	[fetcher setProperty:ticket forKey:kFetcherTicketKey];
	if (handler) {
		[fetcher setProperty:[handler copy] forKey:kFetcherCompletionHandlerKey];
	}
			
	BOOL didFetch = [fetcher beginFetchWithDelegate:self];
	
	if (!didFetch || ticket.used) {
		ticket.fetcher = nil;
		fetcher.properties = nil;
		return nil;
	}
	
	return ticket;
}

- (void)cancelQueryWithTicket:(GGHTTPServiceTicket *)ticket {
	if (!ticket || !ticket.fetcher || ticket.used) {
		return;
	}
	
	[ticket.fetcher stopFetching];
	ticket.fetcher.properties = nil;
	ticket.fetcher = nil;
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
	
	NSURL *url = [self URLForQuery:query];
	if (!url) {
		return nil;
	}
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url 
																 cachePolicy:NSURLRequestReloadIgnoringCacheData
															 timeoutInterval:kGGHTTPServiceDefaultTimeout];
	
	if (!query.httpMethod || [query.httpMethod length] == 0)  {
		query.httpMethod = GGHTTPQueryMethodGET;
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
	
	[self addCommonHeadersToRequest:request];

	id enumerationBlock = ^(id key, id obj, BOOL *stop) {
		[request setValue:obj forHTTPHeaderField:key];
	};
	
	[_additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:enumerationBlock];
	[query.httpHeaders enumerateKeysAndObjectsUsingBlock:enumerationBlock];
	
	if (query.etag && [query.etag length] > 0) {
		[request setValue:query.etag forHTTPHeaderField:@"If-None-Match"];
	}
	
	if (query.lastModified) {
		[request setValue:[query.lastModified RFC2822String] forHTTPHeaderField:@"If-Modified-Since"];
	}
	
	return request;
}

- (NSURL *)URLForQuery:(GGHTTPQuery *)query {	
	NSURL *result = nil;
	
	if (query.url) {
		result = query.url;
	} else if (query.methodName) {
		if (!query.queryPathComponents || [query.queryPathComponents count] == 0) {
			result = [NSURL URLWithString:query.methodName relativeToURL:self.baseURL];
		} else {
			NSMutableArray *pathComponents = [[NSMutableArray alloc] initWithCapacity:1 + [query.queryPathComponents count]];
			[pathComponents addObject:query.methodName];
			
			for (NSString *pathComponent in query.queryPathComponents) {
				[pathComponents addObject:[NSString stringByURLEncodingForURI:pathComponent]];
			}
			
			result = [NSURL URLWithString:[pathComponents componentsJoinedByString:@"/"] relativeToURL:self.baseURL];
			
		}
	}
	
	if (query.queryParameters) {
		result = [result URLByAddingQueryParams:query.queryParameters];
	}
	
	return result;
}

- (void)addCommonHeadersToRequest:(NSMutableURLRequest *)request {
	[request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		
	NSString *uuid = [[UIDevice currentDevice] UUID];
	if (uuid) {
		[request setValue:uuid forHTTPHeaderField:@"X-Device-ID"];
	}
}


- (GGHTTPQueryBody *)requestBodyForQuery:(GGHTTPQuery *)query error:(NSError **)error {
	if (!query.bodyObject) {
		return nil;
	}
	
	if (!query.bodyEncoder) {
		if (error) {
			*error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
										 code:kGGHTTPServiceErrorInvalidRequestBody
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}

	return [query.bodyEncoder encode:query.bodyObject error:error];
}

- (NSObject <GGHTTPCacheProtocol> *)cacheForQuery:(GGHTTPQuery *)query {
	if (query.cachePersistently && self.persistentCache) {
		return self.persistentCache;
	} else {
		return self.cache;
	}
}

#pragma mark -

- (NSString *)userAgent {
	if (_userAgent) {
		return _userAgent;
	}
		
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
	
	_userAgent = [NSString stringWithFormat:@"%@/%@ (%@)", appName, version, [userAgentComponents componentsJoinedByString:@"; "]];

	return _userAgent;
}

#pragma mark - Fetcher callback

- (void)fetcher:(NSObject <GGHTTPFetcherProtocol> *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
	
#if DEBUG_HTTP_SERVICE
	GGLog(@"%d: %@", [fetcher statusCode], [[fetcher mutableRequest] URL]);
#endif

#if DEBUG_HTTP_SERVICE && DEBUG_HTTP_SERVICE_RESPONSE_HEADERS
	GGLog(@"%@", [fetcher responseHeaders]);
#endif
	
#if DEBUG_HTTP_SERVICE && DEBUG_HTTP_SERVICE_RESPONSE_BODY
	GGLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
#endif
	
	GGHTTPServiceTicket *ticket = [fetcher propertyForKey:kFetcherTicketKey];
	ticket.used = YES;
	
	void(^handler)(GGHTTPServiceTicket *ticket, id object, NSError *error) = nil;
	handler = [fetcher propertyForKey:kFetcherCompletionHandlerKey];
	
	if (!handler) {
		ticket.fetcher = nil;
		return;
	}
	
	id object = nil;
	NSHTTPURLResponse *response = nil;
	if ([fetcher.response isKindOfClass:[NSHTTPURLResponse class]]) {
		response = (NSHTTPURLResponse *)(fetcher.response);
	}
	
	if ([fetcher statusCode] == kGGHTTPFetcherStatusNotModified && ticket.cacheItem) {
		[[self cacheForQuery:ticket.query] bumpAgeOfCachedItem:ticket.cacheItem];
		
		object = ticket.cacheItem;
		error = nil;
	} else if (error || [fetcher statusCode] >= 300) {
		object = [self objectWithResponseData:data
								  contentType:[self contentTypeFromResponse:response]
								  bodyDecoder:nil
						  expectedResultClass:[NSDictionary class]
										error:nil];
		
		if (!error) {
			error = [NSError errorWithDomain:kGGHTTPFetcherStatusDomain
										code:[fetcher statusCode]
								 description:nil
							   failureReason:nil];
		}
		
	} else {
		object = [self objectWithResponseData:data
								  contentType:[self contentTypeFromResponse:response]
								  bodyDecoder:ticket.query.bodyDecoder
						  expectedResultClass:ticket.query.expectedResultClass
										error:&error];
		
		if (object && !error) {
			[[self cacheForQuery:ticket.query] storeData:data
											  forRequest:fetcher.mutableRequest
												response:response];
		}
	}

	ticket.fetcher = nil;
	handler(ticket, object, error);
}

- (id)objectWithResponseData:(NSData *)data
				 contentType:(NSString *)contentType
				 bodyDecoder:(Class)bodyDecoder
		 expectedResultClass:(Class)expectedResultClass
					   error:(NSError **)error {
	
	if (!data || [data length] == 0) {
		return nil;
	}
	
	id result = nil;
	
	if (!bodyDecoder && contentType) {
		if ([contentType caseInsensitiveCompare:@"application/json"]) {
			bodyDecoder = [GGHTTPQueryBodyJSONTransformer class];
		}
	}
		
	if (bodyDecoder) {
		result = [bodyDecoder decode:data error:error];
		if (error && *error) {
			return nil;
		}
		
		if (expectedResultClass && ![result isKindOfClass:expectedResultClass]) {
			if (error) {
				*error = [NSError errorWithDomain:kGGHTTPServiceErrorDomain
											 code:kGGHTTPServiceErrorInvalidResponseData
									  description:NSLocalizedString(@"Error", nil)
									failureReason:nil];
			}
			return nil;
		}
		
	} else if (expectedResultClass == [UIImage class] && [contentType hasPrefix:@"image/"]) {
		result = [[UIImage alloc] initWithData:data];
		if (!result) {
			result = data;
		}
	} else {
		result = data;
	}
					
	return result;
}

- (NSString *)contentTypeFromResponse:(NSHTTPURLResponse *)response {
	NSDictionary *responseHeaderFields = [response allHeaderFields];
	__block NSString *result = nil;
	
	[responseHeaderFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if ([key caseInsensitiveCompare:@"Content-Type"] == NSOrderedSame) {
			result = obj;
			*stop = YES;
		}
	}];
	
	return result;
}

@end
