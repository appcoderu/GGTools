//
//  GGStoreProduct.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 22.01.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import "GGStoreProduct.h"
#import <StoreKit/StoreKit.h>

@implementation GGStoreProduct

@synthesize meta=_meta, originalProduct=_product;

- (id)initWithProduct:(SKProduct *)product {
	self = [super init];
	
	if (self) {
		_product = product;
	}
	
	return self;
}

#pragma mark -

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
	
	BOOL eq = NO;
	
	if (self.hash == ((GGStoreProduct *)other).hash) {
		eq = YES;
	}
	
    return eq;
}

- (NSUInteger)hash {
	unsigned int prime = 31;
	unsigned int result = 1;
	
	result = prime * result;
	if (_product.productIdentifier) {
		result += [_product.productIdentifier hash];
	}
	
    return result;
}

#pragma mark -

- (NSString *)title {
	return [_product localizedTitle];
}

- (NSString *)description {
	return [_product localizedDescription];
}

- (NSDecimalNumber *)price {
	return [_product price];
}

- (NSString *)formattedPrice {
	return [self formattedPriceForAmount:1.0f];
}

- (NSString *)formattedPriceForAmount:(float)amount {
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[numberFormatter setLocale:_product.priceLocale];
	NSString *result = [numberFormatter stringFromNumber:[_product.price decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithFloat:amount] decimalValue]]]];
	
	return result;
}

- (NSString *)identifier {
	return [_product productIdentifier];
}

@end
