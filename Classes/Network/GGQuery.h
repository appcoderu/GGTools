//
//  GGQuery.h
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const GGQueryHTTPMethodGET;
extern NSString * const GGQueryHTTPMethodPUT;
extern NSString * const GGQueryHTTPMethodPOST;
extern NSString * const GGQueryHTTPMethodPATCH;
extern NSString * const GGQueryHTTPMethodDELETE;

@interface GGQuery : NSObject

+ (id)queryForMethodName:(NSString *)methodName;

+ (id)queryForURL:(NSURL *)url;
+ (id)queryForURL:(NSURL *)url revalidateInterval:(NSTimeInterval)revalidateInterval;

- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key;
- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key;

- (void)addQueryPathComponent:(NSString *)component;

@property (nonatomic, retain) NSString *methodName;
@property (nonatomic, retain) NSURL *url;

@property (nonatomic, retain) NSString *httpMethod;
@property (nonatomic, retain) NSString *etag;
@property (nonatomic, retain) NSDate *lastModified;

@property (nonatomic, assign) NSTimeInterval revalidateInterval;
@property (nonatomic, assign) BOOL cachePersistently;

@property (nonatomic, retain) id bodyObject;
@property (nonatomic, assign) Class bodyDecoder;
@property (nonatomic, assign) Class bodyEncoder;

@property (nonatomic, assign) Class expectedResultClass;

@property (nonatomic, assign) BOOL suppressAuthorization;

@property(nonatomic, retain) NSDictionary *httpHeaders;
@property(nonatomic, retain) NSDictionary *queryParameters;
@property(nonatomic, retain) NSArray *queryPathComponents;

@end
