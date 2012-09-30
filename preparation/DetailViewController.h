//
//  DetailViewController.h
//  preparation
//
//  Created by Larry on 9/4/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate,UIWebViewDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) NSString *contentType;
@end
