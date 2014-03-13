//
//  NSManagedObject+Actions.h
//
//  Created by Sebastian Kruschwitz on 03.09.13.
//  MIT licence
//

#import <CoreData/CoreData.h>

/**
 Category for NSManagedObject instances.
 The methods are wrapping general CoreData aspects (create, find, delete, ...).
 The general structure and the idea were used from MagicalRecord, but I wanted to have such methods without using MagicalRecord (it is great and better, but I don't need it in every project).
 */
@interface NSManagedObject (Actions)


#pragma mark - UUID

+ (NSString *)createUUID;


#pragma mark - Create

/**
 Creates a new entity and returns it.
 @param context NSManagedObjectContext in which the entry will be created
 @return Created entry
 */
+ (id)createInContext:(NSManagedObjectContext*)context;

/**
 Creates a new entity with the given properties in the record and returns the instance.
 @param context NSManagedObjectContext in which the entry will be created
 @param record NSDictionary with the parameter. This method is parsing this parameter and will assign the values to the corresponding properties of the entity.
 @return Created entry
 */
+ (id)createInContext:(NSManagedObjectContext*)context forRecord:(NSDictionary *)record;


#pragma mark - Update

/**
 Update the entry with the given record.
 The record will be used to overwrite the properties of the entity.
 @param record NSDictionary with the attributes
 */
- (void)updateWithRecord:(NSDictionary *)record;

/**
 Set the given value for the entity property with the equal key name.
 This method will check different edge cases for some properties/keys.
 @param value Value for the property
 @param key Key of the property
 */
- (void)setParsedValue:(id)value forKey:(NSString *)key;


#pragma mark - Fetch

/**
 Fetch all entities in the given context.
 @param context NSManagedObjectContext that will be used for the fetch
 @return All entries, or nil by an error
 */
+ (NSArray*)fetchAllInContext:(NSManagedObjectContext*)context;

/**
 Fetch all entities in the given context sorted by the given key.
 @param sortKey Key for the attribute to sort by
 @param context NSManagedObjectContext that will be used for the fetch
 @return All entities sorted by sortKey, or nil by an error
 */
+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context;

+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context withLimit:(int)limit;

+ (NSArray*)fetchAllSortedBy:(NSString*)sortKey ascending:(BOOL)ascending inContext:(NSManagedObjectContext*)context withLimit:(int)limit;

/**
 Fetch all entities by the given key and value.
 @param key Attribute name
 @param value Value for the given key
 @param context NSManagedObjectContext that will be used for the fetch
 @param limit Fetch limit, if set to 0 this parameter won't be used (no fetch limit will be set), otherwise the given fetch limit will be set to the NSFetchRequest
 @return All entities that match the key with the value, or by an error nil
 */
+ (NSArray*)fetchBy:(NSString*)key withValue:(id)value inContext:(NSManagedObjectContext*)context withLimit:(int)limit;

+ (NSArray*)fetchBy:(NSString *)key withValue:(id)value sortBy:(NSString*)sortKey inContext:(NSManagedObjectContext *)context withLimit:(int)limit;

/**
 Fetch the first entity that match the given key and value.
 @param key Attribute name
 @param value Value for the given key
 @param context NSManagedObjectContext that will be used for the fetch
 @return First entity that match the key and value, or nil by an error or no entry is found
 */
+ (id)fetchFirstByKey:(NSString*)key withValue:(id)value inContext:(NSManagedObjectContext*)context;

/**
 Fetch all entities matching the given predicate.
 @param predicate NSPredicate that defines the fetch
 @param context NSManagedObjectContext that will be used for the fetch
 @return All matching entities, nil if no entries are found
 */
+ (NSArray*)fetchByPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context;

+ (NSArray*)fetchByPredicate:(NSPredicate*)predicate sortBy:(NSString*)sortKey inContext:(NSManagedObjectContext*)context;

/**
 Fetch first entity matching the given predicate.
 
 A normal fetch will return a set of entities. To avoid using an NSArray as a return type this method can be used.
 The method will fetch all matching objects according to the giben predicate and will return the first entry of the result list. No sorting will be used.
 @param predicate NSPredicate that defines the fetch
 @param context NSManagedObjectContext that will be used for the fetch
 @return First matching entity, nil if no entry are found
 */
+ (id)fetchFirstByPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context;

+ (NSArray*)managedObjectsForKey:(NSString*)key sortedByKey:(NSString *)sortKey usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds inContext:(NSManagedObjectContext*)context;

/**
 Fetch all entities and sort them by the given key. Then return the first one.
 
 @param key     The attibute name that will be used to sort the entities
 @param context NSManagedObjectContext that will be used for the fetch
 @return The first entry in the sorted list of results, nil if no entries are found
 */
+ (id)fetchFirstSortedBy:(NSString*)key inContext:(NSManagedObjectContext*)context;

/**
 Sort the entities by the given key and return the last one.
 @param key     Attribute name that will be used for sorting
 @param context NSManagedObjectContext that will be used for the fetch
 @return Last entity according to the sorted list
 */
+ (id)fetchLastSortedBy:(NSString*)key inContext:(NSManagedObjectContext*)context;


#pragma mark - Delete

/**
 Deletes the entity from the context and saves the context.
 @param context NSManagedObjectContext for the delete action
 @return YES when delete was successful otherwise NO
 */
- (BOOL)deleteInContext:(NSManagedObjectContext*)context;

/**
 Deletes all entities in the given context and saves the context.
 @param context NSManagedObjectContext for the delete action
 @return YES when delete was successful otherwise NO
 */
+ (BOOL)truncateAllInContext:(NSManagedObjectContext*)context andSave:(BOOL)save;


#pragma mark - Aggregation

/**
 Count the entities in the given context.
 @param context NSManagedObjectContext for the request
 @return number of objects
 */
+ (NSInteger)numberInContext:(NSManagedObjectContext*)context;

+ (NSInteger)numberInContext:(NSManagedObjectContext *)context withPredicate:(NSPredicate*)predicate;

/**
 Checks if an entity with the given value for the key exists.
 @param key Attribute name
 @param value for the given key
 @param context NSManagedObjectContext for the request
 @return Yes when an entity exists otherwise NO
 */
+ (BOOL)existsForKey:(NSString*)key value:(id)value inContext:(NSManagedObjectContext*)context;


@end
