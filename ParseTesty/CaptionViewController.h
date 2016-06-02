//
//  CaptionViewController.h
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface CaptionViewController : UIViewController

@property (strong, nonatomic) UIImage *theImage;
@property (strong, nonatomic) NSArray *userArray;
@property (assign, nonatomic) CLLocationCoordinate2D currentUserCoordinate;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *captionTextField;
@property (weak, nonatomic) IBOutlet UIButton *postButton;

@end
