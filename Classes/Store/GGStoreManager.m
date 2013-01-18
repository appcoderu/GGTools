//
//  GGStoreManager.m
//  GGFramework
//
//  Created by Evgeniy Shurakov on 21.01.11.
//  Copyright 2011 Evgeniy Shurakov. All rights reserved.
//

#import "GGStoreManager.h"
#import "GGStoreManagerDelegate.h"
#import "GGStoreProduct.h"

#import "NSError+GGExtra.h"

//#define GGStoreManagerVerificationServerPath @"http://localhost/verify.php"

#ifdef GGStoreManagerVerificationServerPath
#import "GGHTTPService.h"
#import "GGHTTPServiceTicket.h"
#import "GGHTTPQuery.h"
#import "GGHTTPQueryResult.h"
#import "GGHTTPQueryBodyFormTransformer.h"
#import "GGHTTPQueryBodyJSONTransformer.h"

#import "NSData+GGBase64.h"
#import "UIDevice+GGUUID.h"
#import "NSString+GGEscape.h"
#endif

#import <StoreKit/StoreKit.h>

NSString * const GGStoreManagerErrorDomain = @"GGStoreManagerErrorDomain";

static NSString * const GGStoreManagerPrefix = @"GGStoreManager_%@";
static const CFSetCallBacks weakSetValuesCallbacks = {0, NULL, NULL, NULL, NULL, NULL};

@interface GGStoreManager () <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@end

@implementation GGStoreManager {
	NSMutableSet *_products; // validated and ready to be sold
	
	NSMutableSet *_rawProducts;
	NSMutableSet *_invalidProducts;
	
	SKProductsRequest *_productsRequest;
	
	// weak set
	NSMutableSet *_delegates;

#ifdef GGStoreManagerVerificationServerPath
	NSMutableSet *_verificationTickets;
#endif
}

+ (GGStoreManager *)sharedInstance {
	static GGStoreManager *sharedInstance = nil;
	static dispatch_once_t pred;
	
	dispatch_once(&pred, ^{
		sharedInstance = [[self alloc] init];
	});
	
	return sharedInstance;
}

- (id)init {
	if ((self = [super init])) {
		_products = [[NSMutableSet alloc] init];
		_rawProducts = [[NSMutableSet alloc] init];
		_invalidProducts = [[NSMutableSet alloc] init];
		
		_productsRequest = nil;
		_delegates = CFBridgingRelease(CFSetCreateMutable(NULL, 0, &weakSetValuesCallbacks));
		
#ifdef GGStoreManagerVerificationServerPath
		_verificationTickets = [[NSMutableSet alloc] initWithCapacity:2];
#endif
		
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	}
	return self;
}

#pragma mark -

+ (BOOL)canMakePayments {
	return [SKPaymentQueue canMakePayments];
}

#pragma mark - Delegate

- (void)addDelegate:(NSObject<GGStoreManagerDelegate> *)delegate {
	[_delegates addObject:delegate];
}

- (void)removeDelegate:(NSObject<GGStoreManagerDelegate> *)delegate {
	[_delegates removeObject:delegate];
}

#pragma mark -

- (NSSet *)productsToValidate {
	NSMutableSet *result = nil;
	if (_rawProducts && [_rawProducts count] > 0) {
		result = [NSMutableSet setWithSet:_rawProducts];
		
		// minus validated products
		if (_products) {
			for (GGStoreProduct *product in _products) {
				[result removeObject:product.identifier];
			}
		}
		
		// minus bad products
		[result minusSet:_invalidProducts];	
	}
	
	return result;
}

- (BOOL)hasMoreProductsToValidate {
	return ([[self productsToValidate] count] > 0);
}

- (BOOL)isValidatingProducts {
	return (_productsRequest ? YES : NO);
}

- (void)addRawProducts:(NSSet *)items {
	[self addRawProducts:items validate:YES];
}

- (void)addRawProducts:(NSSet *)items validate:(BOOL)validate {
	if (!items || [items count] == 0) {
		return;
	}
	[_rawProducts unionSet:items];
	if (validate) {
		[self validateRawProducts];
	}
}

- (void)resetInvalidProducts {
	[_invalidProducts removeAllObjects];
}

- (void)validateRawProducts {
	if (_productsRequest) {
		return;
	}
	
	NSSet *productsRequestIdentifiers = [self productsToValidate];
			
	if (!productsRequestIdentifiers || [productsRequestIdentifiers count] == 0) {
		return;
	}
	
	_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productsRequestIdentifiers];
	_productsRequest.delegate = self;
	[_productsRequest start];
}

- (NSSet *)products {
	return _products;
}

- (GGStoreProduct *)productWithProductIdentifier:(NSString *)productIdentifier {
	GGStoreProduct *result = nil;
	if (!_products || !productIdentifier) {
		return result;
	}
	
	for (GGStoreProduct *product in _products) {
		if ([productIdentifier isEqualToString:[product identifier]]) {
			result = product;
			break;
		}
	}
	
	return result;
}

- (BOOL)isProductInvalid:(NSString *)productIdentifier {
	if (!productIdentifier) {
		return false;
	}
	
	return [_invalidProducts containsObject:productIdentifier];
}

- (void)buyProductWithProductIdentifier:(NSString *)productIdentifier {
	GGStoreProduct *product = [self productWithProductIdentifier:productIdentifier];
	if (product) {
		[self buyProduct:product];
	} else {
		NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
												code:0
										 description:NSLocalizedString(@"Error", @"")
									   failureReason:NSLocalizedString(@"No product specified", @"")];
		
		for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
			if ([delegate respondsToSelector:@selector(storeManager:recievedError:forProduct:)]) {
				[delegate storeManager:self 
						 recievedError:error 
							forProduct:nil];
			}
		}
	}
}

- (void)buyProduct:(GGStoreProduct *)product {
	if (!product) {
		return;
	}
		
	// search for existing transaction in progress
	NSArray *transactions = [[SKPaymentQueue defaultQueue] transactions];
	for (SKPaymentTransaction *transaction in transactions) {
		NSString *productIdentifier = transaction.payment.productIdentifier ? transaction.payment.productIdentifier : transaction.originalTransaction.payment.productIdentifier;
		
		if (!productIdentifier || ![productIdentifier isEqualToString:product.identifier]) {
			continue;
		}
		
		if (transaction.transactionState == SKPaymentTransactionStatePurchasing) {
			return;
		} else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
			continue;
		} else if (transaction.transactionState == SKPaymentTransactionStatePurchased ||
				   transaction.transactionState == SKPaymentTransactionStateRestored) {
#ifdef GGStoreManagerVerificationServerPath
			for (GGHTTPServiceTicket *ticket in _verificationTickets) {
				if (ticket.used) {
					continue;
				}
				
				NSString *productIdentifier = [ticket.query propertyForKey:@"productIdentifier"];
				if (productIdentifier && [productIdentifier isEqualToString:product.identifier]) {
					// we're verifying this transaction right now
					return;
				}
			}
			
			[self postTransactionToServer:transaction];
			return;
#endif
		}
	}
	
	SKPayment *payment = [SKPayment paymentWithProduct:product.originalProduct];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (BOOL)hasBoughtProductWithProductIdentifier:(NSString *)productIdentifier {
	if (!productIdentifier) {
		return NO;
	} else {
		return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:GGStoreManagerPrefix, productIdentifier]];
	}
}

- (BOOL)hasBoughtProduct:(GGStoreProduct *)product {
	return [self hasBoughtProductWithProductIdentifier:[product identifier]];
}

- (NSSet *)hasBoughtProducts:(NSSet *)aProducts {
	NSMutableSet *result = [NSMutableSet setWithCapacity:[aProducts count]];
	for (GGStoreProduct *product in aProducts) {
		if ([self hasBoughtProduct:product]) {
			[result addObject:product];
		}
	}
	return result;
}

- (void)resetBoughtStateForProductWithIdentifier:(NSString *)productIdentifier {
	if (!productIdentifier) {
		return;
	}
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:GGStoreManagerPrefix, productIdentifier]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)markProductAsBought:(GGStoreProduct *)product {
	if (!product) {
		return;
	}
	[[NSUserDefaults standardUserDefaults] setBool:YES 
											forKey:[NSString stringWithFormat:GGStoreManagerPrefix, [product identifier]]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

- (void)recievedError:(NSError *)error forProduct:(GGStoreProduct *)product {	
	if (error && [[error domain] isEqualToString:SKErrorDomain] && [error code] == SKErrorPaymentCancelled) {
		error = nil;
	}
	
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:recievedError:forProduct:)]) {
			[delegate storeManager:self recievedError:error forProduct:product];
		}
	}
}

- (void)purchasedProduct:(GGStoreProduct *)product {	
	[self markProductAsBought:product];
	
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:purchasedProduct:)]) {
			[delegate storeManager:self purchasedProduct:product];
		}
	}
}

- (void)restorePurchases {
	if (![[self class] canMakePayments]) {
		return;
	}
	
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManagerStartedRestoringTransactions:)]) {
			[delegate storeManagerStartedRestoringTransactions:self];
		}
	}
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		BOOL restored = NO;
		switch (transaction.transactionState) {
			case SKPaymentTransactionStateFailed: {
				GGStoreProduct *product = [self productWithProductIdentifier:transaction.payment.productIdentifier];
				[self recievedError:transaction.error forProduct:product];
								
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}

			case SKPaymentTransactionStateRestored:
				restored = YES;
				
			case SKPaymentTransactionStatePurchased: {		
#ifdef GGStoreManagerVerificationServerPath
				[self postTransactionToServer:transaction];
#else
				GGStoreProduct *product = [self productWithProductIdentifier:transaction.payment.productIdentifier];
				[self purchasedProduct:product];

				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
#endif

				break;
			}
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:finishedRestoringTransactionsWithError:)]) {
			[delegate storeManager:self finishedRestoringTransactionsWithError:nil];
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:finishedRestoringTransactionsWithError:)]) {
			[delegate storeManager:self finishedRestoringTransactionsWithError:error];
		}
	}
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {	
	NSMutableSet *fetchedProducts = [NSMutableSet set];
	NSSet *fetchedInvalidProducts = nil;
	
	if (response.products) {
		for (SKProduct *product in response.products) {
			[fetchedProducts addObject:[[GGStoreProduct alloc] initWithProduct:product]];
		}
	}
	
	[_products unionSet:fetchedProducts];
	
	if (response.invalidProductIdentifiers) {
		fetchedInvalidProducts = [NSSet setWithArray:response.invalidProductIdentifiers];
		[_invalidProducts unionSet:fetchedInvalidProducts];
	}
	
	_productsRequest = nil;
	
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:validatedProducts:invalidProducts:)]) {
			[delegate storeManager:self 
				 validatedProducts:fetchedProducts 
				   invalidProducts:fetchedInvalidProducts];
		}
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	if (request != _productsRequest) {
		return;
	}
	
	_productsRequest = nil;
	
	for (NSObject<GGStoreManagerDelegate> *delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(storeManager:recievedError:forProduct:)]) {
			[delegate storeManager:self recievedError:error forProduct:nil];
		}
	}
}

- (void)requestDidFinish:(SKRequest *)request {
	if (request == _productsRequest) {
		_productsRequest = nil;
	}
	
	[self validateRawProducts];
}

#ifdef GGStoreManagerVerificationServerPath
#pragma mark -

- (void)postTransactionToServer:(SKPaymentTransaction *)transaction {	
	if (!transaction) {
		NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
												code:0
										 description:NSLocalizedString(@"Error", @"")
									   failureReason:NSLocalizedString(@"No transaction provided", @"")];
		
		[self recievedError:error forProduct:nil];
		return;
	}
	
	NSString *productIdentifier = transaction.payment.productIdentifier ? transaction.payment.productIdentifier : transaction.originalTransaction.payment.productIdentifier;
	
	GGStoreProduct *product = [self productWithProductIdentifier:productIdentifier];
	if (!product) {
		NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
												code:0
										 description:NSLocalizedString(@"Error", @"")
									   failureReason:NSLocalizedString(@"Product not found", @"")];
		[self recievedError:error forProduct:nil];
		return;
	}
	
	NSData *receiptData = transaction.originalTransaction.transactionReceipt ? transaction.originalTransaction.transactionReceipt : transaction.transactionReceipt;
	NSString *receipt = [receiptData gg_base64EncodingWithLineLength:0];
	
	if (!receipt) {
		NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
												code:0
										 description:NSLocalizedString(@"Error", @"")
									   failureReason:NSLocalizedString(@"Receipt for transaction not found", @"")];
		[self recievedError:error forProduct:product];
		return;
	}
		
	GGHTTPQuery *query = [GGHTTPQuery queryWithURL:[NSURL URLWithString:GGStoreManagerVerificationServerPath]];
	query.cachePolicy = GGHTTPCachePolicyIgnore;
	query.timeout = 30.0;
	query.httpMethod = GGHTTPMethodPOST;
			
	query.bodyObject = @{
		@"product" : productIdentifier,
		@"receipt" : receipt
	};
	query.bodyEncoder = [GGHTTPQueryBodyFormTransformer class];
	query.bodyDecoder = [GGHTTPQueryBodyJSONTransformer class];
	query.expectedResultClass = [NSDictionary class];
	
	UIDevice *currentDevice = [UIDevice currentDevice];
	[query setHTTPHeader:[currentDevice gg_UUID] forKey:@"x-device-uuid"];
	
	[query setProperty:productIdentifier forKey:@"productIdentifier"];
	
	GGHTTPService *service = [GGHTTPService sharedService];
	GGHTTPServiceTicket *ticket = nil;
	__weak GGStoreManager *weakSelf = self;
	
	ticket = [service executeQuery:query
				 completionHandler:^(GGHTTPServiceTicket *ticket, GGHTTPQueryResult *queryResult) {
					 GGStoreManager *localSelf = weakSelf;
					 if (!localSelf) {
						 return;
					 }
					 [localSelf->_verificationTickets removeObject:ticket];
					 
					 if (queryResult.error) {
						 NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
																 code:0
														  description:NSLocalizedString(@"Error", @"")
														failureReason:NSLocalizedString(@"Error connecting to server", @"")];
						 [localSelf recievedError:error forProduct:product];
						 return;
					 }
					 
					 if (![[[queryResult data] objectForKey:@"status"] boolValue]) {
						 NSError *error = [NSError gg_errorWithDomain:GGStoreManagerErrorDomain
																 code:0
														  description:NSLocalizedString(@"Error", @"")
														failureReason:NSLocalizedString(@"Verification on server failed. Please try again later", @"Purchase verification")];
						 [localSelf recievedError:error forProduct:product];
						 return;
					 }
					 
					 [localSelf purchasedProduct:product];
					 [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				 }];
	
	if (ticket && !ticket.used) {
		[_verificationTickets addObject:ticket];
	}
}

#endif

@end
