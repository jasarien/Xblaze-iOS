//
//  XBStoreManager.h
//  Xblaze-iPhone
//
//  Created by James Addyman on 09/04/2012.
//  Copyright (c) 2012 JamSoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

typedef enum {
	
	XBStoreManagerStateIdle,
	XBStoreManagerStateLoadingProducts,
	XBStoreManagerStatePurchasing,
	XBStoreManagerStateRestoring,
	XBStoreManagerStateValidatingReceipt
	
} XBStoreManagerState;

@interface XBStoreManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate> {
	
	NSMutableArray *_products;
	
}

@property (nonatomic, assign) XBStoreManagerState state;

- (NSArray *)products;
- (BOOL)canMakePurchases;
- (void)purchaseProduct:(SKProduct *)product;

@end
