//
//  XBStoreManager.m
//  Xblaze-iPhone
//
//  Created by James Addyman on 09/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import "XBStoreManager.h"

@implementation XBStoreManager

@synthesize state = _state;

static XBStoreManager *_sharedManager;

+ (XBStoreManager *)sharedManager
{
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		_sharedManager = [[self alloc] init];
	});
	return _sharedManager;
}

- (id)init
{
	if ((self = [super init]))
	{
		_products = [[NSMutableArray alloc] init];
		
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
		[self requestProductInformation];
	}
	
	return self;
}

- (void)requestProductInformation
{
	_state = XBStoreManagerStateLoadingProducts;
	
	SKProductsRequest *productsRequest = [[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"com.jamsoftonline.xblaze.xblazepro"]] autorelease];
	[productsRequest setDelegate:self];
	[productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	for (SKProduct *receivedProduct in [response products])
	{
		[_products addObject:receivedProduct];
        NSLog(@"Product title: %@" , receivedProduct.localizedTitle);
        NSLog(@"Product description: %@" , receivedProduct.localizedDescription);
        NSLog(@"Product price: %@" , receivedProduct.price);
        NSLog(@"Product id: %@" , receivedProduct.productIdentifier);
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
}

- (NSArray *)products
{
	return [[_products copy] autorelease];
}

- (BOOL)canMakePurchases
{
	return [SKPaymentQueue canMakePayments];
}

- (void)purchaseProduct:(SKProduct *)product
{
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction*transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];
				break;
			default:
				break;
		}
	}
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
	
}

- (void)provideContent:(NSString *)productId
{
	
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
	[self recordTransaction:transaction];
	[self provideContent:transaction.payment.productIdentifier];
	[self finishTransaction:transaction wasSuccessful:YES];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
	[self recordTransaction:transaction.originalTransaction];
	[self provideContent:transaction.originalTransaction.payment.productIdentifier];
	[self finishTransaction:transaction wasSuccessful:YES];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
	if (transaction.error.code != SKErrorPaymentCancelled)
	{
        [self finishTransaction:transaction wasSuccessful:NO];
	}
	else
	{
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

@end
