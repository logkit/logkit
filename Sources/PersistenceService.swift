//
//  PersistenceService.swift
//  HyperLogKit OSX
//
//  Created by Omer Younus on 2019-09-23.
//  Copyright © 2019 HyperLogKit. All rights reserved.

import Foundation
import CoreData

public class PersistenceService {

   private init() {}
   static var lastTimeStamp:Double = 0

   static var viewContext: NSManagedObjectContext {
       return persistentContainer.viewContext
   }

   static var cacheContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
   }
   
   static var updateContext: NSManagedObjectContext {
        let _updateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        _updateContext.parent = self.viewContext
        return _updateContext
   }
    
   static var persistentContainer: NSPersistentContainer = {
        let messageKitBundle = Bundle(for: LXDataBaseEndpoint.self)
        let modelURL = messageKitBundle.url(forResource: "HyperLogKit", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        let container = NSPersistentContainer(name: "HyperLogKit", managedObjectModel: managedObjectModel!)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
   }()
    
   static func saveChanges() {
        viewContext.performAndWait {
            if viewContext.hasChanges {
                do {
                    try viewContext.save()
                } catch {
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    print("Error: \(error)\nCould not save Core Data context.")
                }
                viewContext.reset() // It will reset the context to clean up the cache and lower the memory.
            }
        }
   }

   static func getLogsFromCoreData() -> [NSManagedObject] {
       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Logs")
       var fetchedResults:[NSManagedObject]? = nil
        do {
            try fetchedResults = viewContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch {
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
        if let results = fetchedResults {
            return results
        } else {
            print("Could not fetch")
        }
        return []
    }
    
    static func addLogs(data: Data)  {
            
       let currentTime = round(NSDate().timeIntervalSince1970 * 1000)
       let predicatedTimeStamp:Double = currentTime - Constants.daysToSaveInMil
       let requestDel = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
       let predicateDel = NSPredicate(format: "timeStamp < %d", argumentArray: [predicatedTimeStamp])
       requestDel.predicate = predicateDel
       
       let delAllReqVar = NSBatchDeleteRequest(fetchRequest:requestDel)

        do {
            try viewContext.execute(delAllReqVar)
        }
        catch {
            NSLog("Failed to delete old data")
        }
       let logMsg = String(decoding: data, as: UTF8.self)
        //Creating Logs entity
       let logs = Logs(context: PersistenceService.viewContext)
       logs.message = logMsg
       logs.sent = false
       logs.timeStamp = NSTimeIntervalSince1970
        
       PersistenceService.saveChanges()
    }
    
    static func updateData() -> String {
       let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Logs")
       fetchRequest.predicate = NSPredicate(format: "sent = %@", "false")
       var resultString = ""

       do {
           let flagDown = try viewContext.fetch(fetchRequest)
           if (flagDown.count > 0){
               for i in 0...flagDown.count - 1{
                   let objectUpdate = flagDown[i] as! NSManagedObject
                   resultString.append("\(objectUpdate.value(forKey: "message") ?? "empty") \n")
                   lastTimeStamp = (objectUpdate.value(forKey: "timeStamp") as! Double)
               }
          }
          else
          {
               return "There is no new logs"
          }
       }
       catch {
            NSLog("Failed to retrieve data, \(error)")
       }
      return resultString;
    }
    
    static func markingSent() {

      if (lastTimeStamp > 0){
           let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Logs")
           fetchRequest.predicate = NSPredicate(format: "timeStamp < %d", argumentArray: [lastTimeStamp])
           do {
               let flagDown = try PersistenceService.viewContext.fetch(fetchRequest)
                if (flagDown.count > 0){
                    for i in 0...flagDown.count - 1{
                        let objectUpdate = flagDown[i] as! NSManagedObject
                        objectUpdate.setValue(true, forKey: "sent")
                    }
                }
                else{
                    NSLog("Failed to change sent flags")
                }
            }
            catch {
                NSLog("Failed to retrieve data, \(error)")
            }
            lastTimeStamp = 0
        }
        else{
            NSLog("Failed to update the sent")
        }
            PersistenceService.saveChanges()
    }
}
