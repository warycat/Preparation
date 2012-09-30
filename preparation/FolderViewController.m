//
//  FolderViewController.m
//  preparation
//
//  Created by Larry on 9/8/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import "FolderViewController.h"

@interface FolderViewController ()
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation FolderViewController
@synthesize pathLabel;
@synthesize dateLabel;

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
    self.dateLabel.text = [self.folder objectForKey:@"LastModified"];
    self.pathLabel.text = self.path;
}

- (void)viewDidUnload
{
    [self setDateLabel:nil];
    [self setPathLabel:nil];
    [super viewDidUnload];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
