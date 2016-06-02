//
//  FeedViewController.m
//  Locify
//
//  Created by Anton Moiseev on 2016-05-30.
//  Copyright © 2016 steve. All rights reserved.
//

#import "FeedViewController.h"
#import "AppDelegate.h"
#import "User.h"
#import "PostCell.h"
#import "Post.h"
#import "DetailViewController.h"
@import MapKit;
@import CoreLocation;

@interface FeedViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray<Post *> *otherUsersPosts;

@end

@implementation FeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // make this view controller the datasource and the delegate of the tableView
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortOtherUsersByDistanceAndSortTheirPostsByTime];
    });
    // set up refresh control
    [self setUpRefreshControl];
    // set title
    self.title = @"Feed";
    // hide cell separators
    self.tableView.separatorColor = [UIColor clearColor];
}

- (void)setUpRefreshControl {
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
}

- (void)refreshTable:(UIRefreshControl *) sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortOtherUsersByDistanceAndSortTheirPostsByTime];
        [sender endRefreshing];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.otherUsersPosts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"feedCell"];
    Post *post = self.otherUsersPosts[indexPath.row];
    cell.postImageView.contentMode = UIViewContentModeScaleAspectFit;
    cell.postImageView.image = [UIImage imageWithData:[post.file getData]];
    if (post.caption) {
        cell.captionLabel.text = post.caption;
    }
    return cell;
    
}

#pragma mark - sorting and displaying other user's posts

- (void)sortOtherUsersByDistanceAndSortTheirPostsByTime {
    User *user = self.userArray[0];
    // get the user's current location
    PFQuery *userQuery = [PFQuery queryWithClassName:@"User"];
    PFObject *theUser = [userQuery getObjectWithId:user.id];
    CLLocationCoordinate2D userCoordinate = CLLocationCoordinate2DMake([theUser[@"lat"] doubleValue], [theUser[@"lng"] doubleValue]);
    MKMapPoint userLocation = MKMapPointForCoordinate(userCoordinate);
    // get other users around the main user
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    [query whereKey:@"objectId" notEqualTo:user.id];
    NSMutableArray *otherUsersNearby = [NSMutableArray new];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable otherUsers, NSError * _Nullable error) {
        // get all the users that are nearby (in a 3km radius)
        for (PFObject *otherUser in otherUsers) {
            CLLocationCoordinate2D otherUserCoordinate = CLLocationCoordinate2DMake([otherUser[@"lat"] doubleValue], [otherUser[@"lng"] doubleValue]);
            MKMapPoint otherUserLocation = MKMapPointForCoordinate(otherUserCoordinate);
            CLLocationDistance distance = MKMetersBetweenMapPoints(otherUserLocation, userLocation);
            NSLog(@"%f", distance);
            if (distance < 3000.0) {
                [otherUsersNearby addObject:otherUser];
            }
        }
        // get all other users' posts
        NSMutableArray *allPosts = [NSMutableArray new];
        for (PFObject *user in otherUsersNearby) {
            if (user[@"images"]) {
                [allPosts addObjectsFromArray:user[@"images"]];
            }
        }
        // get all dates
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
        self.otherUsersPosts = timeOrderedPosts;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"detailSegue"]) {
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        DetailViewController *dvc = segue.destinationViewController;
        dvc.thePost = self.otherUsersPosts[indexPath.row];
    }
}

@end
