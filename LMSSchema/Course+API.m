//
//  Course+API.m
//  LMSSchema
//
//  Created by Joan Coyne on 10/1/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "Course+API.h"
#import "APIFetcher.h"

@implementation Course (API)

+ (Course *)courseFromAPI:(NSDictionary *)courseDictionary
inManagedObjectContext:(NSManagedObjectContext *)context
{
    Course *course = nil;
    
    NSInteger courseId = [ courseDictionary[COURSE_ID] integerValue];
    //check to see if we already have this in the db
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Course"];
    request.predicate = [NSPredicate predicateWithFormat:@"id = %d",courseId];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] >1){
        //handle error
    } else if ([matches count]) {
        course = [matches firstObject];
    
    } else {
        course = [NSEntityDescription insertNewObjectForEntityForName:@"Course"
                                               inManagedObjectContext:context];
        course.course_id = [courseDictionary valueForKeyPath:COURSE_ID];
        course.name = [courseDictionary valueForKeyPath:SINGLE_COURSE_TITLE];
        course.course_description = [courseDictionary valueForKeyPath:COURSE_DESCRIPTION];
        course.created_at = [courseDictionary valueForKeyPath:COURSE_CREATED_AT];
        course.updated_at = [courseDictionary valueForKeyPath:COURSE_UPDATED_AT];
        course.image = [courseDictionary valueForKeyPath:COURSE_IMAGE];
        course.xsmall_image = [courseDictionary valueForKeyPath:COURSE_IMAGE_XSMALL];
        course.small_image = [courseDictionary valueForKeyPath:COURSE_IMAGE_SMALL];
        course.medium_image = [courseDictionary valueForKeyPath:COURSE_IMAGE_MEDIUM];
        course.large_image = [courseDictionary valueForKeyPath:COURSE_IMAGE_LARGE];
    }
    return course;
    
}

@end
