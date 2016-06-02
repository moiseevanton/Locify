//
//  PostCell.h
//  Locify
//
//  Created by Anton Moiseev on 2016-05-31.
//  Copyright © 2016 steve. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;

@end
