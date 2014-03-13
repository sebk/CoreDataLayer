//
//  NSManagedObject+KK.m
//
//  Created by Sebastian Kruschwitz on 03.09.13.
//  MIT licence
//

#import "NSManagedObject+Actions.h"
#import "CoreDataLayer.h"


@implementation NSManagedObject (Actions)

+ (NSString*)entityName {
    return NSStringFromClass(self);
}

#pragma mark - UUID

+ (NSString *)createUUID {
    return [[NSUUID UUID] UUIDString];
}


#pragma mark - Date Formatter

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString {
    // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
    dateString = [dateString substringWithRange:NSMakeRange(0, 19)];
    return [[[CoreDataLayer sharedInstance] dateFormatter] dateFromString:dateString];
}


#pragma mark - Create

+ (id)createInContext:(NSManagedObjectContext*)context {
    NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
    return entity;
}

+ (id)createInContext:(NSManagedObjectContext*)context forRecord:(NSDictionary *)record {
    NSManagedObject *newManagedObject = [self createInContext:context];
    
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [newManagedObject setParsedValue:obj forKey:key];
    }];
    
    return newManagedObject;
}

- (void)updateWithRecord:(NSDictionary *)record {
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setParsedValue:obj forKey:key];
    }];
}

- (void)setParsedValue:(id)value forKey:(NSString *)key {
    
    NSArray *availableKeys = [[self.entity attributesByName] allKeys];
    if (![availableKeys containsObject:key]) {
        return;
    }
    
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]] ) {
        //do nothing
    }
    else {
        [self setValue:value forKey:key];

    }
}


#pragma mark - Fetch

+ (NSArray*)fetchAllInContext:(NSManagedObjectContext*)context {
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ELog(@"Error in fetching all managed objects: %@", error.localizedDescription);
        return nil;
    }
    return results;
}

+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context {
    
    return [self fetchAllSortedBy:sortKey inContext:context withLimit:0];
}

+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context withLimit:(int)limit {
    
    return [self fetchAllSortedBy:sortKey ascending:YES inContext:context withLimit:limit];
}

+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey ascending:(BOOL)ascending inContext:(NSManagedObjectContext*)context withLimit:(int)limit {
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    if (limit > 0) {
        [fetchRequest setFetchLimit:limit];
    }
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ELog(@"Error in fetching all managed objects sorted: %@", error.localizedDescription);
        return nil;
    }
    return results;
}

+ (NSArray*)fetchBy:(NSString *)key withValue:(id)value sortBy:(NSString*)sortKey inContext:(NSManagedObjectContext *)context withLimit:(int)limit {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:[self entityName]];
    
    if (limit > 0) {
        [request setFetchLimit:limit];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    [request setPredicate:predicate];
    
    if (sortKey) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
        [request setSortDescriptors:@[sortDescriptor]];
    }
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (error) {
        ELog(@"Error in fetchBy:withValue: %@", error.localizedDescription);
        return nil;
    }
    return results;
}

+ (NSArray*)fetchBy:(NSString*)key withValue:(id)value inContext:(NSManagedObjectContext*)context withLimit:(int)limit {
    return [self fetchBy:key withValue:value sortBy:nil inContext:context withLimit:limit];
}

+ (id)fetchFirstByKey:(NSString*)key withValue:(id)value inContext:(NSManagedObjectContext*)context {
    NSArray *results = [self fetchBy:key withValue:value inContext:context withLimit:1];
    if (results && results.count > 0) {
        return results[0];
    }
    else {
        return nil;
    }
}

+ (id)fetchFirstSortedBy:(NSString*)key inContext:(NSManagedObjectContext*)context {
    NSArray *results = [self fetchAllSortedBy:key inContext:context];
    if (results && results.count > 0) {
        return results[0];
    }
    else {
        return nil;
    }
}

+ (id)fetchLastSortedBy:(NSString*)key inContext:(NSManagedObjectContext*)context {
    NSArray *results = [self fetchAllSortedBy:key inContext:context];
    if (results && results.count > 0) {
        return results[results.count-1];
    }
    else {
        return nil;
    }
}

+ (id)fetchFirstByPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context {
    return [[self fetchByPredicate:predicate inContext:context] objectAtIndex:0];
}

+ (NSArray*)fetchByPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context {
    return [self fetchByPredicate:predicate sortBy:nil inContext:context];
}

+ (NSArray*)fetchByPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *description = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
    [fetchRequest setEntity:description];
    
    [fetchRequest setPredicate:predicate];
    
    if (sortKey && sortKey.length > 0) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
    }
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        ELog(@"Error in fetching managed object: %@", error.localizedDescription);
        return nil;
    }
    if (fetchedObjects.count == 0) {
        return nil;
    }
    
    return fetchedObjects;
}


+ (NSArray *)managedObjectsForKey:(NSString*)key sortedByKey:(NSString *)sortKey usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds inContext:(NSManagedObjectContext*)context {
        
    NSArray *results = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    NSPredicate *predicate;
    if (inIds) {
        predicate = [NSPredicate predicateWithFormat:@"%K IN %@", key, idArray];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"NOT (%K IN %@)", key, idArray];
    }
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:
                                      [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:YES]]];
    NSError *error = nil;
    results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        ELog(@"Error in fetchig managed objects: %@", error.localizedDescription);
    }
    
    return results;
}


#pragma mark - Delete

- (BOOL)deleteInContext:(NSManagedObjectContext*)context {
    [context deleteObject:self];
    
    NSError *error = nil;
    if (![context save:&error]) {
        return NO;
    }
    return YES;
}

+ (BOOL)truncateAllInContext:(NSManagedObjectContext*)context andSave:(BOOL)save {
    NSArray *instances = [self fetchAllInContext:context];
    for (NSManagedObject *obj in instances) {
        [context deleteObject:obj];
    }
    
    if (save) {
        NSError *error = nil;
        if (![context save:&error]) {
            return NO;
        }
    }
 
    return YES;
}


#pragma mark - Aggregation

+ (NSInteger)numberInContext:(NSManagedObjectContext*)context {
    return [self numberInContext:context withPredicate:nil];
}

+ (NSInteger)numberInContext:(NSManagedObjectContext *)context withPredicate:(NSPredicate*)predicate {
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    [fetchRequest setEntity:entity];
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    if (error) {
        ELog(@"ERROR in requesting number of entities: %@", error.localizedDescription);
    }
    
    return count;
}

+ (BOOL)existsForKey:(NSString*)key value:(id)value inContext:(NSManagedObjectContext*)context {
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc]init];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    if (count == 0) {
        return NO;
    }
    
    return YES;
}

@end
