//
//  Post.h
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

@import UIKit;
@import CoreLocation;
#import "Parse.h"
#import "Bolts.h"

@interface Post : NSObject

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) PFFile *file;
@property (strong, nonatomic) NSString *caption;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate file:(PFFile *)file caption:(NSString *)caption;

@end
