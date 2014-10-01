//
//  Course.h
//  LMSSchema
//
//  Created by Joan Coyne on 10/1/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Course : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * course_description;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSDate * updated_at;
@property (nonatomic, retain) NSString * media;
@property (nonatomic, retain) NSNumber * course_id;
@property (nonatomic, retain) NSString * xsmall_image;
@property (nonatomic, retain) NSString * small_image;
@property (nonatomic, retain) NSString * medium_image;
@property (nonatomic, retain) NSString * large_image;

@end
