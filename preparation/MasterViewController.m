//
//  MasterViewController.m
//  preparation
//
//  Created by Larry on 9/4/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "FolderViewController.h"
#import "FileViewController.h"

enum kType {
    kTypePrefix = 0,
    kTypeKey = 1,
    kTypeDot = 2,
};

@interface MasterViewController ()
@property (strong, nonatomic)NSDictionary *response;
@property (strong, nonatomic)NSArray *objects;
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (NSUInteger)typeWithIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *object = [self.objects objectAtIndex:indexPath.row];
    NSString *prefix = [object objectForKey:@"Prefix"];
    NSString *key = [object objectForKey:@"Key"];
    if (prefix) {
        return kTypePrefix;
    }
    if ([key isEqualToString:self.prefix]){
            return kTypeDot;
    }
    return kTypeKey;
}

- (IBAction)refresh:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"http://aws.warycat.com/prep/list.php"];
    if (self.prefix && ![self.prefix isEqualToString:@""]) {
        NSString *escapedPrefix = [self.prefix stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *parameter = [@"?prefix=" stringByAppendingString:escapedPrefix];
        URL = [NSURL URLWithString:parameter relativeToURL:URL];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSLog(@"%@",request);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (data) {
            self.response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        id contents = [self.response objectForKey:@"Contents"];
        id commonPrefixes = [self.response objectForKey:@"CommonPrefixes"];
        if ([commonPrefixes isKindOfClass:[NSArray class]]) {
            [array addObjectsFromArray:commonPrefixes];
        }
        if ([commonPrefixes isKindOfClass:[NSDictionary class]]) {
            [array addObject:commonPrefixes];
        }
        if ([contents isKindOfClass:[NSArray class]]) {
            [array addObjectsFromArray:contents];
        }
        if ([contents isKindOfClass:[NSDictionary class]]) {
            [array addObject:contents];
        }
        self.objects = [NSArray arrayWithArray:array];
        [self.tableView reloadData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"%@",self.response);
    }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.prefix) {
        self.title = self.prefix;
    }else{
        self.prefix = @"";
    }
    [self refresh:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSDictionary *object = [self.objects objectAtIndex:indexPath.row];
    NSUInteger type = [self typeWithIndexPath:indexPath];
    switch (type) {
        case kTypePrefix:
        {
            NSString *folder = [object objectForKey:@"Prefix"];
            folder = [folder substringFromIndex:self.prefix.length];
            cell.textLabel.text = folder;
        }
            break;
        case kTypeDot:
            cell.textLabel.text = @".";
            break;
        case kTypeKey:
        {
            NSString *key = [object objectForKey:@"Key"];
            key = [key substringFromIndex:self.prefix.length];
            cell.textLabel.text = key;
        }
            break;
        default:
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.objects objectAtIndex:indexPath.row];
    NSUInteger type = [self typeWithIndexPath:indexPath];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];    
    switch (type) {
        case kTypePrefix:
        {
            MasterViewController *mvc = [storyboard instantiateViewControllerWithIdentifier:@"MasterViewController"];
            mvc.prefix = [object objectForKey:@"Prefix"];
            [self.navigationController pushViewController:mvc animated:YES];
        }
            break;
        case kTypeDot:
        {
            FolderViewController *fvc = [storyboard instantiateViewControllerWithIdentifier:@"FolderViewController"];
            fvc.folder = object;
            fvc.path = [object objectForKey:@"Key"];
            [self.navigationController pushViewController:fvc animated:YES];
        }
            break;
        case kTypeKey:
        {
            FileViewController *fvc = [storyboard instantiateViewControllerWithIdentifier:@"FileViewController"];
            fvc.file = object;
            fvc.path = self.prefix;
            [self.navigationController pushViewController:fvc animated:YES];
        }
            break;
        default:
            break;
    }
}


@end
