//
//  FileViewController.h
//  preparation
//
//  Created by Larry on 9/26/12.
//  Copyright (c) 2012 Larry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileViewController : UITableViewController<NSURLConnectionDataDelegate,UIAlertViewDelegate>
@property (nonatomic, strong) NSDictionary *file;
@property (nonatomic, strong) NSString *path;
@end
