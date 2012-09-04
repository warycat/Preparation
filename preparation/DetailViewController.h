//
//  DetailViewController.h
//  preparation
//
//  Created by Larry on 9/4/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
