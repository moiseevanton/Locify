//
//  CaptionViewController.m
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

#import "CaptionViewController.h"
#import "Parse.h"
#import "Bolts.h"
#import "User.h"

@interface CaptionViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic) CGFloat bottomConstraintConstant;

@end

@implementation CaptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // make this view controller the delegate of the caption text field
    self.captionTextField.delegate = self;
    // set up notifications for keyboard
    [self getConstraintConstantAndSetUpNotifications];
    // set up the post button and text field
    [self setUpButtonAndTextField];
    // set up the view
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView {
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.image = self.theImage;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)getConstraintConstantAndSetUpNotifications {
    self.bottomConstraintConstant = self.bottomConstraint.constant;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardShow:(NSNotification *)notification {
    
    NSValue *value = notification.userInfo[UIKeyboardFrameBeginUserInfoKey];
    CGRect rect = [value CGRectValue];
    CGFloat keyboardHeight = rect.size.height;
    self.bottomConstraint.constant = keyboardHeight + self.bottomConstraintConstant;
    self.imageView.alpha = 0.6;
    
}

- (void)keyboardHide:(NSNotification *) notification {
    
    self.bottomConstraint.constant = self.bottomConstraintConstant;
    self.imageView.alpha = 1;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)setUpButtonAndTextField {
    [self.postButton addTarget:self action:@selector(pushImage:) forControlEvents:UIControlEventTouchUpInside];
    self.captionTextField.alpha = 0.9;
}

#pragma mark - pushing data to parse

- (void)pushImage:(UIButton *)sender {
    // do something to the image
    NSData *imageData = UIImageJPEGRepresentation(self.theImage, 0.7);
    PFFile *imageFile = [PFFile fileWithName:@"image.jpeg" data:imageData];
    
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    User *user = self.userArray[0];
    [query getObjectInBackgroundWithId:user.id block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object[@"images"]) {
            if (self.captionTextField.text) {
                [object addObject:@[[NSDate date], imageFile,[NSNumber numberWithDouble:self.currentUserCoordinate.latitude], [NSNumber numberWithDouble:self.currentUserCoordinate.longitude], self.captionTextField.text] forKey:@"images"];
            } else {
                [object addObject:@[[NSDate date], imageFile,[NSNumber numberWithDouble:self.currentUserCoordinate.latitude], [NSNumber numberWithDouble:self.currentUserCoordinate.longitude]] forKey:@"images"];
            }
        } else {
            if (self.captionTextField.text) {
                [object addUniqueObject:@[[NSDate date], imageFile, [NSNumber numberWithDouble:self.currentUserCoordinate.latitude], [NSNumber numberWithDouble:self.currentUserCoordinate.longitude], self.captionTextField.text] forKey:@"images"];
            } else {
                [object addUniqueObject:@[[NSDate date], imageFile, [NSNumber numberWithDouble:self.currentUserCoordinate.latitude], [NSNumber numberWithDouble:self.currentUserCoordinate.longitude]] forKey:@"images"];
            }
        }
        [object saveInBackground];
    }];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
