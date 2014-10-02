//
//  AppDelegate.m
//  LMSSchema
//
//  Created by Joan Coyne on 10/1/14.
//  Copyright (c) 2014 Mzinga. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDelegate+MOC.h"
#import "APIFetcher.h"
#import "Course+API.h"
#import "CourseDatabaseAvailability.h"


@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^APIDownloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *APIDownloadSession;
@property (strong, nonatomic) NSTimer  *APIForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *courseDatabaseContext;


@end


// name of the Flickr fetching background download session
#define API_FETCH @"API Just Uploaded Fetch"

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_API_FETCH_INTERVAL (20*60)

// how long we'll wait for a Flickr fetch to return when we're in the background
#define BACKGROUND_API_FETCH_TIMEOUT (10)


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // when we're in the background, fetch as often as possible (which won't be much)
    // forgot to include this line in the demo during lecture, but don't forget to include it in your app!
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // we get our managed object context by creating it ourself in a category on PhotomaniaAppDelegate
    // but in your homework assignment, you must get your context from a UIManagedDocument
    // (i.e. you cannot use the method createMainQueueManagedObjectContext, or even use that approach)
    self.courseDatabaseContext = self.createMainQueueManagedObjectContext;
    [self startAPIFetch];

    return YES;
}

#pragma mark - Database Context

// we do some stuff when our Photo database's context becomes available
// we kick off our foreground NSTimer so that we are fetching every once in a while in the foreground
// we post a notification to let others know the context is available

- (void)setCourseDatabaseContext:(NSManagedObjectContext *)courseDatabaseContext
{
    _courseDatabaseContext = courseDatabaseContext;
    
    // every time the context changes, we'll restart our timer
    // so kill (invalidate) the current one
    // (we didn't get to this line of code in lecture, sorry!)
    [self.APIForegroundFetchTimer invalidate];
    self.APIForegroundFetchTimer = nil;
    
    if (self.courseDatabaseContext)
    {
        // this timer will fire only when we are in the foreground
        self.APIForegroundFetchTimer = [NSTimer scheduledTimerWithTimeInterval:FOREGROUND_API_FETCH_INTERVAL
                                                                           target:self
                                                                      selector:@selector(startAPIFetch)
                                                                         userInfo:nil
                                                                          repeats:YES];
    }
    
    // let everyone who might be interested know this context is available
    // this happens very early in the running of our application
    // it would make NO SENSE to listen to this radio station in a View Controller that was segued to, for example
    // (but that's okay because a segued-to View Controller would presumably be "prepared" by being given a context to work in)
    NSDictionary *userInfo = self.courseDatabaseContext ? @{ CourseDatabaseAvailabilityContext : self.courseDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:CourseDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];
}

#pragma mark - API Fetching

// this will probably not work (task = nil) if we're in the background, but that's okay
// (we do our background fetching in performFetchWithCompletionHandler:)
// it will always work when we are the foreground (active) application

- (void)startAPIFetch
{
    // getTasksWithCompletionHandler: is ASYNCHRONOUS
    // but that's okay because we're not expecting startFlickrFetch to do anything synchronously anyway
    [self.APIDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        // let's see if we're already working on a fetch ...
        if (![downloadTasks count]) {
            // ... not working on a fetch, let's start one up
            NSURLSessionDownloadTask *task = [self.APIDownloadSession downloadTaskWithURL:[APIFetcher URLforClassList]];
            task.taskDescription = API_FETCH;
            [task resume];
        } else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}
- (NSURLSession *)APIDownloadSession // the NSURLSession we will use to fetch Flickr data in the background
{
    if (!_APIDownloadSession) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            // notice the configuration here is "backgroundSessionConfiguration:"
            // that means that we will (eventually) get the results even if we are not the foreground application
            // even if our application crashed, it would get relaunched (eventually) to handle this URL's results!
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:API_FETCH];
            _APIDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self    // we MUST have a delegate for background configurations
                                                              delegateQueue:nil];   // nil means "a random, non-main-queue queue"
        });
    }
    return _APIDownloadSession;
}
// standard "get photo information from API URL" code

- (NSArray *)APICoursesAtURL:(NSURL *)url
{
    NSDictionary *APIPropertyList;
    NSData *APIJSONData = [NSData dataWithContentsOfURL:url];  // will block if url is not local!
    if (APIJSONData) {
        APIPropertyList = [NSJSONSerialization JSONObjectWithData:APIJSONData
                                                             options:0
                                                               error:NULL];
    }
    return [APIPropertyList valueForKeyPath:COURSES];
}

// gets the API course dictionaries out of the url and puts them into Core Data
// this was moved here after lecture to give you an example of how to declare a method that takes a block as an argument
// and because we now do this both as part of our background session delegate handler and when background fetch happens

- (void)loadAPICoursesFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)())whenDone
{
    if (context) {
        NSArray *courses = [self APICoursesAtURL:localFile];
        [context performBlock:^{
           
            [Course loadCoursesFromAPIArray:courses  inManagedObjectContext:context];
            [context save:NULL]; // NOT NECESSARY if this is a UIManagedDocument's context
            if (whenDone) whenDone();
        }];
    } else {
        if (whenDone) whenDone();
    }
}


#pragma mark - NSURLSessionDownloadDelegate

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
{
    // we shouldn't assume we're the only downloading going on ...
    if ([downloadTask.taskDescription isEqualToString:API_FETCH]) {
        // ... but if this is the Flickr fetching, then process the returned data
        [self loadAPICoursesFromLocalURL:localFile
                               intoContext:self.courseDatabaseContext
                       andThenExecuteBlock:^{
                           [self APIDownloadTasksMightBeComplete];
                       }
         ];
    }
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // we don't support resuming an interrupted download task
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // we don't report the progress of a download in our UI, but this is a cool method to do that with
}

// not required by the protocol, but we should definitely catch errors here
// so that we can avoid crashes
// and also so that we can detect that download tasks are (might be) complete
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && (session == self.APIDownloadSession)) {
        NSLog(@"API background download session failed: %@", error.localizedDescription);
        [self APIDownloadTasksMightBeComplete];
    }
}

// this is "might" in case some day we have multiple downloads going on at once

- (void)APIDownloadTasksMightBeComplete
{
    if (self.APIDownloadBackgroundURLSessionCompletionHandler) {
        [self.APIDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            // we're doing this check for other downloads just to be theoretically "correct"
            //  but we don't actually need it (since we only ever fire off one download task at a time)
            // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
            //  so we must check again when the block executes if the handler is still not nil
            //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
            if (![downloadTasks count]) {  // any more API downloads left?
                // nope, then invoke APIDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
                void (^completionHandler)() = self.APIDownloadBackgroundURLSessionCompletionHandler;
                self.APIDownloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            } // else other downloads going, so let them call this method when they finish
        }];
    }
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.mzinga.com.LMSSchema" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LMSSchema" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LMSSchema.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
