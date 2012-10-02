//
//  InAppPurchaseManager.h
//  preparation
//
//  Created by Larry on 10/1/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"

@interface InAppPurchaseManager : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>

- (void)list:(NSString*) featureId;

- (void) buyFeature:(NSString*) featureId
         onComplete:(void (^)(NSString* purchasedFeature, NSData*purchasedReceipt)) completionBlock
        onCancelled:(void (^)(void)) cancelBlock;
@end
