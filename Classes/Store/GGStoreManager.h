//
//  GGStoreManager.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 21.01.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const GGStoreManagerErrorDomain;

@class GGStoreProduct;
@protocol GGStoreManagerDelegate;

@interface GGStoreManager : NSObject

+ (GGStoreManager *)sharedInstance;
+ (BOOL)canMakePayments;

- (void)addDelegate:(NSObject<GGStoreManagerDelegate> *)delegate;
- (void)removeDelegate:(NSObject<GGStoreManagerDelegate> *)delegate;

- (void)addRawProducts:(NSSet *)items;
- (void)addRawProducts:(NSSet *)items validate:(BOOL)validate;

- (void)validateRawProducts;

- (BOOL)hasMoreProductsToValidate;
- (BOOL)isValidatingProducts;

- (void)resetInvalidProducts;
- (BOOL)isProductInvalid:(NSString *)productIdentifier;

- (NSSet *)products;
- (GGStoreProduct *)productWithProductIdentifier:(NSString *)productIdentifier;

- (void)buyProduct:(GGStoreProduct *)product;
- (void)buyProductWithProductIdentifier:(NSString *)productIdentifier;

- (BOOL)hasBoughtProduct:(GGStoreProduct *)product;
- (BOOL)hasBoughtProductWithProductIdentifier:(NSString *)productIdentifier;

- (NSSet *)hasBoughtProducts:(NSSet *)products;

- (void)resetBoughtStateForProductWithIdentifier:(NSString *)productIdentifier;

- (void)restorePurchases;

@end
