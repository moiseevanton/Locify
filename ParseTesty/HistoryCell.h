//
//  HistoryCell.h
//  Locify
//
//  Created by Anton Moiseev on 2016-06-02.
//  Copyright © 2016 steve. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *historyImageView;
@property (weak, nonatomic) IBOutlet UILabel *historyCaptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *historyLocationLabel;

@end
