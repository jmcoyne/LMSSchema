//
//  ClassesCDTV.m
//  LMSSchema
//
//  Created by Joan Coyne on 10/1/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "ClassesCDTV.h"
#import "Course.h"
#import "CourseDatabaseAvailability.h"


@implementation ClassesCDTV

- (void)awakeFromNib {
    //Should probably move this.  It only works here because we know we instantiate from the storyboard
    [[NSNotificationCenter defaultCenter] addObserverForName:CourseDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[CourseDatabaseAvailabilityContext];
                                                  }];
    
}
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    
    _managedObjectContext = managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Course"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedStandardCompare:)]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil ];
    
    
}
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Course Cell"];
    Course *course = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = course.name;
    cell.detailTextLabel.text = course.description;
    
    return cell;
    
}
@end
