//
//  Post.m
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

#import "Post.h"

@implementation Post

- (instancetype)init {
    
    return [self initWithCoordinate:CLLocationCoordinate2DMake(0, 0) file:nil caption:nil];
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate file:(PFFile *)file caption:(NSString *)caption {
    
    self = [super init];
    
    if (self) {
        _coordinate = coordinate;
        _file = file;
        _caption = caption;
    }
    return self;
}
@end
