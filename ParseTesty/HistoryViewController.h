//
//  HistoryViewController.h
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;
@import CoreLocation;
#import "User.h"
#import "Parse.h"
#import "Bolts.h"
#import "Post.h"
#import "HistoryCell.h"

@interface HistoryViewController : UIViewController

@property (strong, nonatomic) NSArray *userArray;

@end
