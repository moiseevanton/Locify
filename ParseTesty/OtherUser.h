//
//  OtherUser.h
//  Locify
//
//  Created by Anton Moiseev on 2016-05-31.
//  Copyright © 2016 steve. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;

@interface OtherUser : NSObject <MKAnnotation>

@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;

@end
