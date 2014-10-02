//
//  AppDelegate+MOC.h
//  LMSSchema
//
//  Created by Joan Coyne on 10/2/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (MOC)
- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;
@end
