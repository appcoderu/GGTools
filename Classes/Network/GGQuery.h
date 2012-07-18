//
//  GGQuery.h
//  GGFramework
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

@property (nonatomic, strong) NSString *methodName;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSString *etag;
@property (nonatomic, strong) NSDate *lastModified;

@property (nonatomic, assign) NSTimeInterval revalidateInterval;
@property (nonatomic, assign) BOOL cachePersistently;

@property (nonatomic, strong) id bodyObject;
@property (nonatomic, weak) Class bodyDecoder;
@property (nonatomic, weak) Class bodyEncoder;

@property (nonatomic, weak) Class expectedResultClass;

@property (nonatomic, assign) BOOL suppressAuthorization;

@property(nonatomic, strong) NSDictionary *httpHeaders;
@property(nonatomic, strong) NSDictionary *queryParameters;
@property(nonatomic, strong) NSArray *queryPathComponents;

@end
