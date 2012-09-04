//
//  MasterViewController.h
//  preparation
//
//  Created by Larry on 9/4/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
