//
//  GGStoreManagerDelegate.h
//  GGFramework
//
//  Created by Evgeniy Shurakov on 21.01.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GGStoreManager;
@class GGStoreProduct;

@protocol GGStoreManagerDelegate
@optional
- (void)storeManager:(GGStoreManager *)manager purchasedProduct:(GGStoreProduct *)product;
- (void)storeManager:(GGStoreManager *)manager recievedError:(NSError *)error forProduct:(GGStoreProduct *)product;

- (void)storeManager:(GGStoreManager *)manager startedValidatingProducts:(NSSet *)products;
- (void)storeManager:(GGStoreManager *)manager validatedProducts:(NSSet *)products invalidProducts:(NSSet *)invalidProductsIdentifiers;

- (void)storeManagerStartedRestoringTransactions:(GGStoreManager *)manager;
- (void)storeManager:(GGStoreManager *)manager finishedRestoringTransactionsWithError:(NSError *)error;

@end
