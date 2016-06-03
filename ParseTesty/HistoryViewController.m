//
//  HistoryViewController.m
//  Locify
//
//  Created by Anton Moiseev on 2016-06-01.
//  Copyright © 2016 steve. All rights reserved.
//

#import "HistoryViewController.h"
#import "DetailViewController.h"

@interface HistoryViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *historyTableView;
@property (strong, nonatomic) NSMutableArray *theUsersPosts;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // set this view controller as the data source and the delegate for the table view
    self.historyTableView.dataSource = self;
    self.historyTableView.delegate = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortUsersPosts];
    });
    // refresh control
    [self setUpRefreshControl];
    // set title
    self.title = @"Your Posts";
    // hide cell separators
    self.historyTableView.separatorColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSIndexPath *indexPath = [self.historyTableView indexPathForSelectedRow];
    [self.historyTableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.historyTableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
}

- (void)refreshTable:(UIRefreshControl *) sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortUsersPosts];
        [sender endRefreshing];
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.theUsersPosts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HistoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"historyCell"];
    Post *post = self.theUsersPosts[indexPath.row];
    cell.historyImageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.historyImageView.image = [UIImage imageWithData:[post.file getData]];
    if (post.caption) {
        cell.historyCaptionLabel.text = post.caption;
    }
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    CLLocation *location = [CLLocation new];
    location = [location initWithLatitude:post.coordinate.latitude longitude:post.coordinate.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = placemarks[0];
        cell.historyLocationLabel.text = placemark.thoroughfare;
    }];
    return cell;
    
}

- (void)sortUsersPosts {
    User *user = self.userArray[0];
    // get the user's current location
    PFQuery *userQuery = [PFQuery queryWithClassName:@"User"];
    PFObject *theUser = [userQuery getObjectWithId:user.id];
    
    NSMutableArray *allPosts = [NSMutableArray new];
    if (theUser[@"images"]) {
        [allPosts addObjectsFromArray:theUser[@"images"]];
    }
    
    NSMutableArray *allDates = [NSMutableArray new];
    NSMutableDictionary *dateToImageDict = [NSMutableDictionary new];
    for (NSArray *post in allPosts) {
        if (post[0]) {
            [allDates addObject:post[0]];
            if (post.count == 4) {
                dateToImageDict[post[0]] = @[post[1], post[2], post[3]];
            }
            if (post.count == 5) {
                dateToImageDict[post[0]] = @[post[1], post[2], post[3], post[4]];
            }
        }
    }
    
    [allDates sortUsingSelector:@selector(compare:)];
    NSArray *allDatesOrdered = [NSArray new];
    allDatesOrdered = [[allDates reverseObjectEnumerator] allObjects];
    NSMutableArray *timeOrderedPosts = [NSMutableArray new];
    for (NSDate *date in allDatesOrdered) {
        NSArray *contentArray = dateToImageDict[date];
        PFFile *postFile = contentArray[0];
        double lat = [contentArray[1] doubleValue];
        double lng = [contentArray[2] doubleValue];
        NSString *caption;
        if (contentArray.count == 4) {
            caption = contentArray[3];
        }
        Post *post = [[Post alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lng) file:postFile caption:caption];
        [timeOrderedPosts addObject:post];
    }
    self.theUsersPosts = timeOrderedPosts;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.historyTableView reloadData];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.historyTableView indexPathForSelectedRow];
    DetailViewController *dvc = segue.destinationViewController;
    dvc.thePost = self.theUsersPosts[indexPath.row];
}

@end
