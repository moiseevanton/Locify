//
//  ViewController.m
//  ParseTesty
//
//  Created by steve on 2016-05-28.
//  Copyright © 2016 steve. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "User.h"
@import MapKit;
@import CoreLocation;
#import "FeedViewController.h"
#import "OtherUser.h"
#import "CaptionViewController.h"
#import "HistoryViewController.h"

@interface MainViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) BOOL shouldZoomToUserLocation;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (strong, nonatomic) NSManagedObjectContext *moc;
@property (strong, nonatomic) NSArray *userArray;
@property (assign, nonatomic) CLLocationCoordinate2D currentUserCoordinate;
@property (weak, nonatomic) IBOutlet UILabel *howManyOtherUsersLabel;
@property (strong, nonatomic) UIImage *chosenImage;
@property (strong, nonatomic) NSArray *otherUserAnnotations;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // make this view controller the delegate of the mapView
    self.mapView.delegate = self;
    // the app should zoom into the users location when the view loads
    self.shouldZoomToUserLocation = YES;
    // set up location services
    [self authorizeLocationServices];
    // show user location
    self.mapView.showsUserLocation = YES;
    // add action to the camera button
    [self.cameraButton addTarget:self action:@selector(cameraButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    // set title
    self.title = @"L◉CIFY";
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self fetchUser];
    
    if (self.userArray.count ==  0) {
        PFObject *user = [PFObject objectWithClassName:@"User"];
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                User *currentUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.moc];
                currentUser.id = user.objectId;
                [self.moc save:nil];
                self.userArray = @[currentUser];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)authorizeLocationServices {
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 10;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    } else if (status == kCLAuthorizationStatusDenied) {
        NSLog(@"User didn't let me use his/her location");
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error getting location: %@", [error localizedDescription]);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D userCoordinate = location.coordinate;
    self.currentUserCoordinate = userCoordinate;
    NSLog(@"lat: %f lng: %f", userCoordinate.latitude, userCoordinate.longitude);
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    User *user = self.userArray[0];
    [query getObjectInBackgroundWithId:user.id block:^(PFObject * _Nullable object, NSError * _Nullable error) {
        object[@"lat"] = [NSNumber numberWithDouble:userCoordinate.latitude];
        object[@"lng"] = [NSNumber numberWithDouble:userCoordinate.longitude];
        [object saveInBackground];
    }];
    
    if (self.shouldZoomToUserLocation) {
        MKCoordinateRegion userRegion = MKCoordinateRegionMake(userCoordinate, MKCoordinateSpanMake(0.005, 0.005));
        [self.mapView setRegion:userRegion animated:YES];
        self.shouldZoomToUserLocation = NO;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortOtherUsersByDistanceAndDisplayThem];
    });
}

#pragma mark - implementation of camera

- (void)cameraButtonTapped {
    [self alertUserWithMessage:@"Take a photo or pick one from the camera roll. Share it with everyone around you!"];
}

- (void)alertUserWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"What would you like to do?" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cameraTapped];
    }];
    UIAlertAction *cameraRollAction = [UIAlertAction actionWithTitle:@"Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cameraRollTapped];
    }];
    [alertController addAction:cameraAction];
    [alertController addAction:cameraRollAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)cameraTapped {
    UIImagePickerControllerSourceType cameraSourceType = UIImagePickerControllerSourceTypeCamera;
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = cameraSourceType;
    imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:cameraSourceType];
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)cameraRollTapped {
    UIImagePickerControllerSourceType photoLibSourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = photoLibSourceType;
    imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:photoLibSourceType];
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    [self dismissViewControllerAnimated:YES completion:^{
        // handle image
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        if ([info[UIImagePickerControllerMediaType] isEqualToString:@"public.image"]) {
            self.chosenImage = image;
            [self performSegueWithIdentifier:@"captionSegue" sender:nil];
        }
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    } else {
        NSLog(@"Success!");
    }
}

- (void)fetchUser {
    AppDelegate *appDel = [UIApplication sharedApplication].delegate;
    self.moc = appDel.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error;
    NSArray *fetchedUsers = [self.moc executeFetchRequest:fetchRequest error:&error];
    self.userArray = fetchedUsers;
}

#pragma mark - passing objects

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"feedSegue"]) {
        // pass the value to the feed view controller
        FeedViewController *fvc = segue.destinationViewController;
        fvc.userArray = self.userArray;
    }
    if ([segue.identifier isEqualToString:@"captionSegue"]) {
        // pass the objects and values to the caption view controller
        CaptionViewController *cvc = segue.destinationViewController;
        cvc.theImage = self.chosenImage;
        cvc.userArray = self.userArray;
        cvc.currentUserCoordinate = self.currentUserCoordinate;
    }
    if ([segue.identifier isEqualToString:@"historySegue"]) {
        // pass the objects and values to the history view controller
        HistoryViewController *hvc = segue.destinationViewController;
        hvc.userArray = self.userArray;
    }
}

#pragma mark - sorting and displaying other users

- (void)sortOtherUsersByDistanceAndDisplayThem {
    User *user = self.userArray[0];
    NSLog(@"%@", user.id);
    // get the user's current location
    PFQuery *userQuery = [PFQuery queryWithClassName:@"User"];
    PFObject *theUser = [userQuery getObjectWithId:user.id];
    CLLocationCoordinate2D userCoordinate = CLLocationCoordinate2DMake([theUser[@"lat"] doubleValue], [theUser[@"lng"] doubleValue]);
    MKMapPoint userLocation = MKMapPointForCoordinate(userCoordinate);
    // get other users around the main user
    PFQuery *query = [PFQuery queryWithClassName:@"User"];
    [query whereKey:@"objectId" notEqualTo:user.id];
    NSMutableArray *otherUsersNearby = [NSMutableArray new];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        NSLog(@"%lu users found", objects.count);
        self.howManyOtherUsersLabel.text = [NSString stringWithFormat:@"Users around you: %lu", objects.count];
        for (PFObject *object in objects) {
            CLLocationCoordinate2D otherUserCoordinate = CLLocationCoordinate2DMake([object[@"lat"] doubleValue], [object[@"lng"] doubleValue]);
            OtherUser *otherUser = [OtherUser new];
            otherUser.coordinate = otherUserCoordinate;
            MKMapPoint otherUserLocation = MKMapPointForCoordinate(otherUserCoordinate);
            CLLocationDistance distance = MKMetersBetweenMapPoints(otherUserLocation, userLocation);
            NSLog(@"%f", distance);
            if (distance < 3000.0) {
                otherUser.title = [NSString stringWithFormat: @"%.0f meters away", distance];
                [otherUsersNearby addObject:otherUser];
            }
        }
        if (self.otherUserAnnotations) {
            [self.mapView removeAnnotations:self.otherUserAnnotations];
        }
        self.otherUserAnnotations = otherUsersNearby;
        [self.mapView addAnnotations:otherUsersNearby];
    }];
}
- (IBAction)refreshMap:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self sortOtherUsersByDistanceAndDisplayThem];
    });

}

@end
