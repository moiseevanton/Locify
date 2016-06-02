//
//  User+CoreDataProperties.h
//  
//
//  Created by Anton Moiseev on 2016-05-30.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface User (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *id;

@end

NS_ASSUME_NONNULL_END
