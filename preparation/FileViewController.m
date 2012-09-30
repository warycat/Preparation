//
//  FileViewController.m
//  preparation
//
//  Created by Larry on 9/26/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import "FileViewController.h"
#import "DetailViewController.h"


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
@end

@implementation FileViewController
@synthesize nameLabel = _nameLabel;
@synthesize pathLabel = _pathLabel;
@synthesize dateLabel;
@synthesize sizeLabel;
@synthesize typeLabel;
@synthesize previewCell;
@synthesize deliverCell = _deliverCell;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"file %@",self.file);
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
    NSLog(@"%@",request);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            self.metadata = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"%@",self.metadata);
        self.dateLabel.text = [self.metadata objectForKey:@"LastModified"];
        self.sizeLabel.text = [self.metadata objectForKey:@"Size"];
        self.typeLabel.text = [self.metadata objectForKey:@"ContentType"];
        self.previewCell.userInteractionEnabled = YES;
        self.previewCell.textLabel.enabled = YES;
    }];
    self.previewCell.userInteractionEnabled = NO;
    self.previewCell.textLabel.enabled = NO;

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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.eTag];
                if (![[NSFileManager defaultManager]fileExistsAtPath:path]) {
                    [self cacheFile];
                }else{
                    DetailViewController *dvc = [storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
                    dvc.contentType = [self.metadata objectForKey:@"ContentType"];
                    dvc.detailItem = [NSData dataWithContentsOfFile:path];
                    [self.navigationController pushViewController:dvc animated:YES];
                }
            }
                break;
            case 1:
            {
                self.alertView = [[UIAlertView alloc]initWithTitle:@"Input Email Address" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
                self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [self.alertView show];
                NSLog(@"deliver");
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
    NSLog(@"cacheFile");
    NSString *url = [self.metadata objectForKey:@"URL"];
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSString *tempfile = [NSTemporaryDirectory() stringByAppendingPathComponent:self.eTag];
    NSLog(@"temp %@",tempfile);
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
            self.deliverCell.detailTextLabel.text = [alertView textFieldAtIndex:0].text;
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
    NSLog(@"didReceiveData %d",data.length);
    [self.filehandle writeData:data];
    NSNumberFormatter *f = [[NSNumberFormatter alloc]init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *n = [f numberFromString:[self.file objectForKey:@"Size"]];
    double progress = self.filehandle.offsetInFile * 100.0 / n.doubleValue;
    self.previewCell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f%%",progress];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    NSString *tempfile = [NSTemporaryDirectory() stringByAppendingPathComponent:self.eTag];
    NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:self.eTag];
    [[NSFileManager defaultManager] moveItemAtPath:tempfile toPath:path error:nil];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.previewCell.userInteractionEnabled = YES;
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForCell:self.previewCell] animated:YES];
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

@end
