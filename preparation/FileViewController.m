//
//  FileViewController.m
//  preparation
//
//  Created by Larry on 9/26/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import "FileViewController.h"
#import "DetailViewController.h"
#import "InAppPurchaseManager.h"
#import "Base64/NSData+Base64.h"


@interface FileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *previewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *deliverCell;
@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) NSString *eTag;
@property (strong, nonatomic) NSDictionary *metadata;
@property (strong, nonatomic) NSFileHandle *filehandle;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSDictionary *products;
@end

@implementation FileViewController
@synthesize nameLabel = _nameLabel;
@synthesize pathLabel = _pathLabel;
@synthesize dateLabel;
@synthesize sizeLabel;
@synthesize typeLabel;
@synthesize previewCell;
@synthesize deliverCell = _deliverCell;
@synthesize email = _email;

- (NSString *)email
{
    if (_email) {
        return _email;
    }
    _email = [[NSUserDefaults standardUserDefaults]stringForKey:@"email"];
    return _email;
}

- (void)setEmail:(NSString *)email
{
    if (!email && [email isEqualToString:_email]) {
        return;
    }
    _email = email;
    [[NSUserDefaults standardUserDefaults]setObject:email forKey:@"email"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.key = [self.file objectForKey:@"Key"];
    self.eTag = [self.file objectForKey:@"ETag"];
    self.nameLabel.text = [self.key substringFromIndex:self.path.length];
    self.pathLabel.text = self.path;
    self.dateLabel.text = [self.file objectForKey:@"LastModified"];
    self.sizeLabel.text = [self.file objectForKey:@"Size"];
    NSURL *URL = [NSURL URLWithString:@"http://aws.warycat.com/prep/metadata.php"];
    NSString *escapedFilename = [self.key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *parameter = [@"?filename=" stringByAppendingString:escapedFilename];
    URL = [NSURL URLWithString:parameter relativeToURL:URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            self.metadata = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.dateLabel.text = [self.metadata objectForKey:@"LastModified"];
        self.sizeLabel.text = [self.metadata objectForKey:@"Size"];
        self.typeLabel.text = [self.metadata objectForKey:@"ContentType"];
        self.previewCell.userInteractionEnabled = YES;
        self.previewCell.textLabel.enabled = YES;
    }];
    self.previewCell.userInteractionEnabled = NO;
    self.previewCell.textLabel.enabled = NO;
    self.deliverCell.userInteractionEnabled = NO;
    self.deliverCell.textLabel.enabled = NO;
    [self requestProducts];
}

- (void)viewDidUnload
{
    [self setDateLabel:nil];
    [self setSizeLabel:nil];
    [self setTypeLabel:nil];
    [self setPreviewCell:nil];
    [self setPathLabel:nil];
    [self setNameLabel:nil];
    [self setDeliverCell:nil];
    [super viewDidUnload];
    [self.connection cancel];
    [self setConnection:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    UIStoryboard *storyboard = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:[NSBundle mainBundle]];
    }
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.eTag];
                if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
                    [self cacheFile];
                }else{
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                        DetailViewController *dvc = [storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
                        dvc.contentType = [self.metadata objectForKey:@"ContentType"];
                        dvc.detailItem = [NSData dataWithContentsOfFile:path];
                        [self.navigationController pushViewController:dvc animated:YES];
                    }else{
                        UISplitViewController *svc = self.navigationController.splitViewController;
                        UINavigationController *nvc = svc.viewControllers.lastObject;
                        DetailViewController *dvc = (DetailViewController *)nvc.topViewController;
                        dvc.contentType = [self.metadata objectForKey:@"ContentType"];
                        dvc.detailItem = [NSData dataWithContentsOfFile:path];
                    }
                }
            }
                break;
            case 1:
            {
                self.alertView = [[UIAlertView alloc]initWithTitle:@"Input Email Address" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
                self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                UITextField *textField = [self.alertView textFieldAtIndex:0];
                textField.text = self.email;
                [self.alertView show];
            }
                break;
            default:
                break;
        }
    }else{
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)cacheFile
{
    NSString *url = [self.metadata objectForKey:@"URL"];
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSString *tempfile = [NSTemporaryDirectory() stringByAppendingPathComponent:self.eTag];
    if ([[NSFileManager defaultManager]createFileAtPath:tempfile contents:nil attributes:nil]) {
        self.filehandle = [NSFileHandle fileHandleForWritingAtPath:tempfile];
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [connection start];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.previewCell.userInteractionEnabled = NO;
    }else{
        NSLog(@"Error was code: %d - message: %s", errno, strerror(errno));
    }
}

#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:self.deliverCell];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
            break;
        case 1:
        {
            self.email = [alertView textFieldAtIndex:0].text;
            self.deliverCell.detailTextLabel.text = self.email;
            [self deliverFile];
        }
            break;
        default:
            break;
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *email = [alertView textFieldAtIndex:0].text;
    return [self validateEmail:email];
}

#pragma mark - connection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.filehandle writeData:data];
    NSNumberFormatter *f = [[NSNumberFormatter alloc]init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *n = [f numberFromString:[self.file objectForKey:@"Size"]];
    double progress = self.filehandle.offsetInFile * 100.0 / n.doubleValue;
    self.previewCell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f%%",progress];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *tempfile = [NSTemporaryDirectory() stringByAppendingPathComponent:self.eTag];
    NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.eTag];
    [[NSFileManager defaultManager] moveItemAtPath:tempfile toPath:path error:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.previewCell.userInteractionEnabled = YES;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:self.previewCell];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.previewCell.detailTextLabel.text = error.description;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSString *)applicationDocumentsDirectory
{
    NSURL *URL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return URL.path;
}


- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}


#pragma mark - request products

- (void)requestProducts
{
    NSSet *productIDs = [NSSet setWithObject:@"com.warycat.prep.delivery"];
    SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:productIDs];
    request.delegate = self;
    [request start];
}

- (void)deliverFile
{
    NSLog(@"deliverfile");
    SKProduct *product = [self.products objectForKey:@"com.warycat.prep.delivery"];
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue]addPayment:payment];
}



#pragma mark - products request delegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"didReceiveResponse");
    NSMutableDictionary *products = [NSMutableDictionary dictionary];
    for (SKProduct *product in response.products) {
        [products setObject:product forKey:product.productIdentifier];
        NSLog(@"%@",product.productIdentifier);
    }
    self.products = [NSDictionary dictionaryWithDictionary:products];
    SKProduct *product = [self.products objectForKey:@"com.warycat.prep.delivery"];
    if (!product) {
        return;
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    NSString *currencyString = [formatter stringFromNumber:product.price];
    self.deliverCell.detailTextLabel.text = currencyString;
    self.deliverCell.userInteractionEnabled = YES;
    self.deliverCell.textLabel.enabled = YES;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError %@",error);
}

- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"requestDidFinish");
}

#pragma mark - sk payment transaction observer

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
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
                [self completeTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"complete");
    self.deliverCell.detailTextLabel.text = @"Purchased";
    NSURL *URL = [NSURL URLWithString:@"http://aws.warycat.com/prep/delivery.php"];
    NSData *receiptData = [transaction.transactionReceipt copy];
    NSString *receiptString = [receiptData base64EncodedString];
    NSString *parameter = [NSString stringWithFormat:@"?filename=%@&email=%@&receipt=%@",self.key,self.email,receiptString];
    parameter = [parameter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    URL = [NSURL URLWithString:parameter relativeToURL:URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if(dict){
                NSLog(@"%@",dict);
            }else{
                NSLog(@"%@",[NSString stringWithUTF8String: data.bytes]);
            }
            NSNumber *status = [dict objectForKey:@"status"];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:self.deliverCell];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            NSString *message = nil;
            switch (status.integerValue) {
                case 200:
                    message = @"Delivered";
                    break;
                    
                default:
                    message = status.stringValue;
                    break;
            }
            self.deliverCell.detailTextLabel.text = message;
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"%@ fail",transaction);
    if (transaction.error.code != SKErrorPaymentCancelled) {
        // Optionally, display an error here.
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

@end
