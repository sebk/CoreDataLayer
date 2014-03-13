//
//  CoreDataLayer.h
//
//  Created by Sebastian Kruschwitz on 03.09.13.
//  MIT licence
//

#import <Foundation/Foundation.h>

/**
 Singleton class for handling general Core Data aspects.
 
 The idea is the implementation of a `multi context` approach.
 We are defining separate NSManagedObjectContext instances. One context is using the NSPersistentStoreCoordinator and can write to the desired store.
 Other contexts (temporary contexts) are children of the 'main' context (without a connection to the persistent store) and are used to perfom operations in a separated thread. 
 The 'main' context itself is a child of the 'writer' context. The 'writer' context is the only context with a persistent store coordinator and is initialized as the `NSPrivateQueueConcurrencyType` type.
 
 When you want to do a background operation you can do it in the following order:
 
     NSManagedObjectContext *tmpContext = [[CoreDataLayer sharedInstance] temporaryContext]; //creates a new context
     [tmpContext performBlock:^{
        // do something that takes some time asynchronously using the temp context
 
        [[CoreDataLayer sharedInstance] saveTemporaryContext: tmpContext] completion:;
     }];
 
 In summary:
    * Using one 'writable' context (as NSPrivateQueueConcurrencyType) that is connected to a persistent store
    * Using one 'main' context (as NSMainQueueConcurrencyType) that is used for the UI and is child of the 'writer' context.
    * One or multiple 'background' contexts (as NSPrivateQueueConcurrencyType), children of 'main'
 
 
 A good description can be found here:
 http://www.cocoanetics.com/2012/07/multi-context-coredata/
 
 Another helpfull source:
 http://www.touchwonders.com/fast-and-non-blocking-core-data-back-end-programming/
 
 */
@interface CoreDataLayer : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) NSManagedObjectContext *writerManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext *mainManagedObjectContext;


+ (CoreDataLayer*)sharedInstance;

- (NSManagedObjectContext*)temporaryContext;

- (void)saveTemporaryContext:(NSManagedObjectContext*)tempContext completion:(void (^)(NSError *error))completion;

@end
