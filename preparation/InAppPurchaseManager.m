//
//  InAppPurchaseManager.m
//  preparation
//
//  Created by Larry on 10/1/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//


#import "InAppPurchaseManager.h"
@interface InAppPurchaseManager ()
@property (strong, nonatomic)SKProductsRequest *request;
@property (nonatomic, copy) void (^onTransactionCancelled)();
@property (nonatomic, copy) void (^onTransactionCompleted)(NSString *productId, NSData* receiptData);
@end

@implementation InAppPurchaseManager

- (id)init
{
    if (self = [super init]) {
        if ([SKPaymentQueue canMakePayments]) {
            NSLog(@"canMakePayments");
        }else{
            NSLog(@"error");
        }
        [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
    }
    return self;
}

- (void) buyFeature:(NSString*) featureId
         onComplete:(void (^)(NSString* purchasedFeature, NSData*purchasedReceipt)) completionBlock
        onCancelled:(void (^)(void)) cancelBlock
{
    NSLog(@"buyFeature");
    self.onTransactionCompleted = completionBlock;
    self.onTransactionCancelled = cancelBlock;
    NSSet *productIDs = [NSSet setWithObject:featureId];
    self.request = [[SKProductsRequest alloc]initWithProductIdentifiers:productIDs];
    self.request.delegate = self;
    [self.request start];
}

- (void)list:(NSString*) featureId
{
    NSLog(@"list");
    NSSet *productIDs = [NSSet setWithObject:featureId];
    self.request = [[SKProductsRequest alloc]initWithProductIdentifiers:productIDs];
    self.request.delegate = self;
    NSLog(@"request %@",self.request);
    [self.request start];
}

#pragma mark - SKProducts Request Delegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"productsRequest");
    SKProduct *product = response.products.lastObject;
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue]addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"error %@",error);
}

#pragma mark - SKPayment Transaction Observer

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"paymentQueue");
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                self.onTransactionCompleted(transaction.payment.productIdentifier,transaction.transactionReceipt);
                break;
            case SKPaymentTransactionStateFailed:
                self.onTransactionCancelled();
                break;
            case SKPaymentTransactionStateRestored:
                self.onTransactionCompleted(transaction.payment.productIdentifier,transaction.transactionReceipt);
            default:
                break;
        }
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"complete");
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"restore");

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        // Optionally, display an error here.
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


@end