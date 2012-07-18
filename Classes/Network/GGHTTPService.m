//
//  GGHTTPService.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"

#import "GGQuery.h"
#import "GGQueryBody.h"
#import "GGQueryBodyDecoder.h"
#import "GGQueryBodyEncoder.h"

#import "GGHTTPCache.h"
#import "GGHTTPCacheItem.h"

#import "GGHTTPFetcherProtocol.h"
#import "GGAuthorizationProtocol.h"
#import "GGHTTPCacheProtocol.h"

#import "UIDevice+UUID.h"
#import "NSError+Extra.h"
#import "NSDate+Extra.h"
#import "NSString+Escape.h"
#import "NSDictionary+URL.h"
#import "NSURL+QueryParameters.h"

NSString * const GGHTTPServiceErrorDomain				= @"ru.appcode.serviceError";
const NSInteger GGHTTPServiceErrorInvalidResponseData	= -1;
const NSInteger GGHTTPServiceErrorQueryFailed			= -2;
const NSInteger GGHTTPServiceErrorUnauthorized			= -3;
const NSInteger GGHTTPServiceErrorInvalidRequestBody	= -4;
const NSInteger GGHTTPServiceErrorUnableToConstructRequest = -5;

static NSString * const kFetcherTicketKey				= @"ticket";
static NSString * const kFetcherCompletionHandlerKey	= @"completionHandler";
static NSString * const kFetcherCacheItemKey			= @"cacheItem";

static NSTimeInterval const GGHTTPServiceDefaultTimeout = 30.0;

@implementation GGHTTPService {

}

@synthesize userAgent=userAgent_;
@synthesize baseURL=baseURL_;
@synthesize additionalHTTPHeaders=additionalHTTPHeaders_;

@synthesize cache=cache_;
@synthesize persistentCache=persistentCache_;

@synthesize authorizer=authorizer_;

+ (id)sharedService {
	static GGHTTPService *sharedInstance = nil;
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		sharedInstance = [[self alloc] init];
		sharedInstance.cache = [GGHTTPCache sharedCache];
	});
	
	return sharedInstance;
}

- (id)init {
    return [self initWithBaseURL:nil];
}

- (id)initWithBaseURL:(NSURL *)baseURL {
	self = [super init];
    if (self) {
        baseURL_ = baseURL;
    }
    return self;
}

#pragma mark -


#pragma mark -

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	return [self loadURL:url revalidateInterval:0.0 completionHandler:handler];
}

- (GGHTTPServiceTicket *)loadURL:(NSURL *)url
			  revalidateInterval:(NSTimeInterval)revalidateInterval
			   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	GGQuery *query = [GGQuery queryForURL:url revalidateInterval:revalidateInterval];
	return [self executeQuery:query completionHandler:handler];
}

- (GGHTTPServiceTicket *)executeQuery:(GGQuery *)query
   completionHandler:(void (^)(GGHTTPServiceTicket *ticket, id object, NSError *error))handler {
	if (!query) {
		if (handler) {
			NSError *error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
												 code:GGHTTPServiceErrorUnableToConstructRequest 
										  description:NSLocalizedString(@"Error", nil) 
										failureReason:NSLocalizedString(@"Unable to construct request", nil)];
			handler(nil, nil, error);
		}
		return nil;
	}
		
	NSMutableURLRequest *request = [self requestForQuery:query];
	if (!request) {
		if (handler) {
			NSError *error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
												 code:GGHTTPServiceErrorUnableToConstructRequest 
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
			
	BOOL didFetch = [fetcher beginFetchWithDelegate:self
								  didFinishSelector:@selector(fetcher:finishedWithData:error:)];
	
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
#warning TODO
	return nil;
}

#pragma mark - Construct Request

- (NSMutableURLRequest *)requestForQuery:(GGQuery *)query {
	if (!query) {
		return nil;
	}
	
	NSURL *url = [self URLForQuery:query];
	if (!url) {
		return nil;
	}
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url 
																 cachePolicy:NSURLRequestReloadIgnoringCacheData
															 timeoutInterval:GGHTTPServiceDefaultTimeout];
	
	if (!query.httpMethod || [query.httpMethod length] == 0)  {
		query.httpMethod = GGQueryHTTPMethodGET;
	}
	request.HTTPMethod = query.httpMethod;
	
	NSError *error = nil;
	GGQueryBody *body = [self requestBodyForQuery:query error:&error];
	
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
	
	[additionalHTTPHeaders_ enumerateKeysAndObjectsUsingBlock:enumerationBlock];
	[query.httpHeaders enumerateKeysAndObjectsUsingBlock:enumerationBlock];
	
	if (query.etag && [query.etag length] > 0) {
		[request setValue:query.etag forHTTPHeaderField:@"If-None-Match"];
	}
	
	if (query.lastModified) {
		[request setValue:[query.lastModified RFC2822String] forHTTPHeaderField:@"If-Modified-Since"];
	}
	
	return request;
}

- (NSURL *)URLForQuery:(GGQuery *)query {	
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
	
	UIDevice *device = [UIDevice currentDevice];
	if (device.systemVersion) {
		[request setValue:device.systemVersion forHTTPHeaderField:@"X-OS-Version"];
	}
	
	if (device.model) {
		[request setValue:device.model forHTTPHeaderField:@"X-Device-Model"];
	}
	
	NSString *uuid = [[UIDevice currentDevice] UUID];
	if (uuid) {
		[request setValue:uuid forHTTPHeaderField:@"X-Device-ID"];
	}
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *marketingVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *developmentVersionNumber = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	[request setValue:[NSString stringWithFormat:@"%@/%@", marketingVersionNumber, developmentVersionNumber] forHTTPHeaderField:@"X-App-Version"];
}


- (GGQueryBody *)requestBodyForQuery:(GGQuery *)query error:(NSError **)error {
	if (!query.bodyObject) {
		return nil;
	}
	
	if (!query.bodyEncoder) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidRequestBody 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}

	return [query.bodyEncoder encode:query.bodyObject error:error];
}

- (NSObject <GGHTTPCacheProtocol> *)cacheForQuery:(GGQuery *)query {
	if (query.cachePersistently && self.persistentCache) {
		return self.persistentCache;
	} else {
		return self.cache;
	}
}

#pragma mark -

- (NSString *)userAgent {
	if (userAgent_) {
		return userAgent_;
	}
	
#warning TODO
	
	return userAgent_;
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
	
	if (error || [fetcher statusCode] >= 300) {
		if ([error domain] == kGGHTTPFetcherStatusDomain &&
			[error code] == kGGHTTPFetcherStatusNotModified &&
			ticket.cacheItem) {
			
			[[self cacheForQuery:ticket.query] bumpAgeOfCachedItem:ticket.cacheItem];
			
			object = ticket.cacheItem;
			error = nil;
		} else {
			error = [self errorWithError:error data:data ticket:ticket];
		}		
	} else {
		object = [self objectWithResponseData:data ticket:ticket error:&error];
		if (object && !error) {
			[[self cacheForQuery:ticket.query] storeData:data forRequest:fetcher.request response:fetcher.response];
		}
	}

	ticket.fetcher = nil;
	handler(ticket, object, error);
}

- (id)objectWithResponseData:(NSData *)data ticket:(GGHTTPServiceTicket *)ticket error:(NSError **)error {
	if (!data || [data length] == 0) {
		return nil;
	}
	
	GGQuery *query = ticket.query;
	
	id result = nil;
	
	if (!query.bodyDecoder) {
		result = data;
	} else {
		result = [query.bodyDecoder decode:data error:error];
		if (error && *error) {
			return nil;
		}
	}
		
	if (query.expectedResultClass && ![result isKindOfClass:query.expectedResultClass]) {
		if (error) {
			*error = [NSError errorWithDomain:GGHTTPServiceErrorDomain 
										 code:GGHTTPServiceErrorInvalidResponseData 
								  description:NSLocalizedString(@"Error", nil) 
								failureReason:nil];
		}
		return nil;
	}
	
	// TODO: convert data to image if content-type is image/*
		
	return result;
}

- (NSString *)errorMessageFromData:(NSData *)data {
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSError *)errorWithError:(NSError *)error data:(NSData *)data ticket:(GGHTTPServiceTicket *)ticket {
	NSString *domain = GGHTTPServiceErrorDomain;
	NSInteger code;
	
	if (([error domain] == kGGHTTPFetcherStatusDomain && [error code] == kGGHTTPFetcherStatusUnauthorized) || 
		([error domain] == GGAuthorizationErrorDomain)) {
		code = GGHTTPServiceErrorUnauthorized;
	} else {
		code = GGHTTPServiceErrorQueryFailed;
	}
	
	return [NSError errorWithDomain:domain 
							   code:code 
						description:NSLocalizedString(@"Error", nil) 
					  failureReason:[self errorMessageFromData:data]
					underlyingError:error];
}

@end
