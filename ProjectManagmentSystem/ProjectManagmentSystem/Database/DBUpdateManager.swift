//
//  DBUpdateManager.swift
//  ProjectManagmentSystem
//
//  Created by Siya9 on 29/11/16.
//  Copyright © 2016 Siya9. All rights reserved.
//

import UIKit
import CoreData

class DBUpdateManager: NSObject {

    class func createPrivateMOC(parentMOC :NSManagedObjectContext) -> NSManagedObjectContext {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = parentMOC
        return privateMOC
    }
    class func insertObject(entityName: String, moc :NSManagedObjectContext) -> NSManagedObject {
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        
        fetchRequest.fetchLimit = 1;
        let sortDescriptor = NSSortDescriptor(key: "uID", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let result:NSManagedObject? = DBUpdateManager.executeForContext(theContext: moc, fetchRequest: fetchRequest)?.first as? NSManagedObject
        var uid : NSInteger = 1
        if result != nil {
            uid = result?.value(forKey: "uID") as! NSInteger
            uid += 1
        }
        let newObj:NSManagedObject = NSManagedObject(entity: entity!, insertInto: moc) 
        newObj.setValue(uid, forKey: "uID")
        return newObj
    }
    class func save(parentMOC :NSManagedObjectContext){
        if parentMOC.hasChanges {
            do {
                try parentMOC.save()
            } catch {
                print("An error occurred while save context")
            }
        }
        DBUpdateManager.saveContext(parentMOC: parentMOC.parent)
    }
    class func saveContext(parentMOC :NSManagedObjectContext?){
        if parentMOC == nil {
            return
        }
        if parentMOC?.parent == nil {
            parentMOC?.perform({
                DBUpdateManager.save(parentMOC: parentMOC!)
            })
        }
        else{
            parentMOC?.performAndWait({
                DBUpdateManager.save(parentMOC: parentMOC!)
            })
        }
    }
    class func fetchEntityWith(entityName : String, keyValues: [String: AnyObject] ,moc : NSManagedObjectContext, isCreate : Bool)-> NSManagedObject?{
        //        var keyValues: [String: AnyObject] = ["name" : "John Doe", "age" : 39]
        var predicates = [NSPredicate]()
        
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%K == %@", key, value as! NSObject)
            predicates.append(predicate)
        }
        let compundPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates:predicates)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = compundPredicate
        let result:[Any] = DBUpdateManager.executeForContext(theContext: moc, fetchRequest: fetchRequest)!
        if result.count == 0 && isCreate {
            let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc)
            return NSManagedObject(entity: entity!, insertInto: moc)
        }
        else{
            return result.first as? NSManagedObject
        }
    }
    class func fetchEntityWith(entityName : String, keyValues: [String: AnyObject] ,moc : NSManagedObjectContext)-> [Any]?{
//        var keyValues: [String: AnyObject] = ["name" : "John Doe", "age" : 39]
        var predicates = [NSPredicate]()
        
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%K == %@", key, value as! NSObject)
            predicates.append(predicate)
        }
        let compundPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates:predicates)
        return DBUpdateManager.fetchEntityWith(entityName: entityName, predicate: compundPredicate, moc: moc)
    }
    class func fetchEntityWith(entityName : String, predicate : NSPredicate ,moc : NSManagedObjectContext)-> [Any]?{
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        return DBUpdateManager.executeForContext(theContext: moc, fetchRequest: fetchRequest)
    }
    class func countEntityWith(entityName : String, keyValues: [String: AnyObject] ,moc : NSManagedObjectContext)-> NSInteger {
        //        var keyValues: [String: AnyObject] = ["name" : "John Doe", "age" : 39]
        var predicates = [NSPredicate]()
        
        for (key, value) in keyValues {
            let predicate = NSPredicate(format: "%K == [cd]%@", key, value as! NSObject)
            predicates.append(predicate)
        }
        let compundPredicate = NSCompoundPredicate.init(andPredicateWithSubpredicates:predicates)
        return DBUpdateManager.countEntityWith(entityName: entityName, predicate: compundPredicate, moc: moc)
    }
    class func countEntityWith(entityName : String, predicate : NSPredicate ,moc : NSManagedObjectContext)-> NSInteger{
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        var count:NSInteger = 0
        do {
            try count = moc.count(for: fetchRequest)
        } catch {
            print("Error while executing fetch request occured.")
        }
        return count
    }
    class func deleteEntityWith(entityName : String, predicate : NSPredicate? ,moc : NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        let delete:NSBatchDeleteRequest = NSBatchDeleteRequest.init(fetchRequest: fetchRequest)
        do {
            try moc.persistentStoreCoordinator?.execute(delete, with: moc)
        } catch {
            print("Error while deleting into %@.",entityName)
        }
    }
    class func executeForContext(theContext :NSManagedObjectContext, fetchRequest: NSFetchRequest<NSFetchRequestResult>)-> [Any]? {
        var result = [Any]()
        do {
            try result = theContext.fetch(fetchRequest)
        } catch {
            print("Error while executing fetch request occured.")
        }
        return result
    }
}
