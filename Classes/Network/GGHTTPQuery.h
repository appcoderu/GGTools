//
//  GGHTTPQuery.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 09.04.12.
//  Copyright (c) 2012 AppCode. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const GGHTTPMethodGET;
extern NSString * const GGHTTPMethodPUT;
extern NSString * const GGHTTPMethodPOST;
extern NSString * const GGHTTPMethodPATCH;
extern NSString * const GGHTTPMethodDELETE;

@interface GGHTTPQuery : NSObject

+ (id)queryWithRelativePath:(NSString *)relativePath;
+ (id)queryWithURL:(NSURL *)url;

- (void)setQueryParameter:(NSString *)parameter forKey:(NSString *)key;
- (void)setHTTPHeader:(NSString *)parameter forKey:(NSString *)key;

- (void)addQueryPathComponent:(NSString *)component;

- (void)setProperty:(id)obj forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

@property (nonatomic, strong) NSString *relativePath;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) NSString *httpMethod;

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
