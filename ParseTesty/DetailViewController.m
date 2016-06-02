//
//  DetailViewController.m
//  Locify
//
//  Created by Anton Moiseev on 2016-06-02.
//  Copyright © 2016 steve. All rights reserved.
//

#import "DetailViewController.h"
#import "Parse.h"
#import "Bolts.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *detailImageView;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // set up the view
    [self configureView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView {
    self.detailImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.detailImageView.image = [UIImage imageWithData:[self.thePost.file getData]];
}

@end
