//
//  GGStoreProduct.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 22.01.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

@interface GGStoreProduct : NSObject

@property(nonatomic, retain) NSDictionary *meta;
@property(nonatomic, retain, readonly) SKProduct *originalProduct;

- (id)initWithProduct:(SKProduct *)product;

- (NSString *)title;
- (NSString *)description;
- (NSDecimalNumber *)price;
- (NSString *)formattedPrice;
- (NSString *)formattedPriceForAmount:(float)amount;

- (NSString *)identifier;

@end
