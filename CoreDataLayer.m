//
//  CoreDataLayer.m
//
//  Created by Sebastian Kruschwitz on 03.09.13.
//  MIT licence
//

#import "CoreDataLayer.h"

@interface CoreDataLayer ()

@end


@implementation CoreDataLayer

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize dateFormatter = _dateFormatter;


+ (CoreDataLayer *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    static CoreDataLayer *sharedInstance = nil;

    dispatch_once(&predicate, ^{

        sharedInstance = [[self alloc] init];

    });

    return sharedInstance;
}

- (NSDateFormatter*)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    
    return _dateFormatter;
}


#pragma mark - Core Data stack

- (NSManagedObjectContext *)writerManagedObjectContext {
    if (_writerManagedObjectContext != nil) {
        return _writerManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _writerManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_writerManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _writerManagedObjectContext;
}

- (NSManagedObjectContext *)mainManagedObjectContext {
    if (_mainManagedObjectContext != nil) {
        return _mainManagedObjectContext;
    }

    _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainManagedObjectContext.parentContext = self.writerManagedObjectContext;
    
    return _mainManagedObjectContext;
}

- (NSManagedObjectContext*)temporaryContext {
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = self.mainManagedObjectContext;
    
    return temporaryContext;
}

- (void)saveTemporaryContext:(NSManagedObjectContext*)tempContext completion:(void (^)(NSError *error))completion {
    // push to parent
    NSError *error;
    if (![tempContext save:&error])
    {
        // TODO: handle error
        DumpError(@"saveTemporaryContext#tempContext", error);
        if(completion) completion(error);
    }
    
    // save parent to disk asynchronously
    [self.mainManagedObjectContext performBlock:^{
        NSError *error;
        if (![_mainManagedObjectContext save:&error])
        {
            // TODO: handle error
            DumpError(@"saveTemporaryContext#mainContext", error);
            if(completion) completion(error);
        }
        else {
            [self.writerManagedObjectContext performBlock:^{
                NSError *error;
                if (![_writerManagedObjectContext save:&error]) {
                    //TODO: handle error
                    DumpError(@"saveTemporaryContext#writeContext", error);
                    if(completion) completion(error);
                }
                else {
                    NSLog(@"SAVING ALL CONTEXT FINISHED");
                    if(completion) completion(nil);
                }
            }];
        }
    }];
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    //@synchronized(self) {
        if (_managedObjectModel != nil) {
            return _managedObjectModel;
        }
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        return _managedObjectModel;
    //}
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    //@synchronized(self) {
        
        if (_persistentStoreCoordinator != nil) {
            return _persistentStoreCoordinator;
        }
        
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"KAP2go.sqlite"];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error]) {
                        
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            ELog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        return _persistentStoreCoordinator;
    //}
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Error handling

void DumpError(NSString* action, NSError* error) {
    
    if (!error)
        return;
    
    NSLog(@"Failed to %@: %@", action, [error localizedDescription]);
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(detailedErrors && [detailedErrors count] > 0) {
        for(NSError* detailedError in detailedErrors) {
            NSLog(@"DetailedError: %@", [detailedError userInfo]);
        }
    }
    else {
        NSLog(@"%@", [error userInfo]);
    }
}


@end
