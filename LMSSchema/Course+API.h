//
//  Course+API.h
//  LMSSchema
//
//  Created by Joan Coyne on 10/1/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "Course.h"
#import "APIFetcher.h"

@interface Course (API)
+ (Course *)ourseFromAPI:(NSDictionary *)courseDictionary
   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (void)loadCoursesFromAPIArray:(NSArray *)photos // of API NSDictionary
       inManagedObjectContext:(NSManagedObjectContext *)context;

@end
