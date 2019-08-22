// DatabaseEndpoints.swift
//
// Copyright (c) 2015 - 2016, Kasiel Solutions Inc. & The LogKit Project
// http://www.logkit.info/
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import Foundation
import CoreData

struct Constants {
    static let daysToSave = 7
    static let daysToSaveInMil = Double(daysToSave * 24 * 60 * 60 * 1000)
}

public class LXDataBaseEndpoint {
    
    //TODO: Apply HTTPEndpoints methods to send recorded logs to the server as per request
    
    lazy var persistentContainer: NSPersistentContainer = {
        let messageKitBundle = Bundle(identifier: "info.logkit.LogKit")
        let modelURL = messageKitBundle!.url(forResource: "LogKit", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        let container = NSPersistentContainer(name: "LogKit", managedObjectModel: managedObjectModel!)
 
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                //Replace fatalError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                //Replace fatalError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func createData(){
        let managedContext = persistentContainer.viewContext
        
        //Trimming DB if it has older than "predicatedTimeStamp"
        let currentTime = round(NSDate().timeIntervalSince1970 * 1000)
        let predicatedTimeStamp:Double = currentTime - Constants.daysToSaveInMil
        let requestDel = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
        let predicateDel = NSPredicate(format: "timeStamp < %d", argumentArray: [predicatedTimeStamp])
        requestDel.predicate = predicateDel
   
        do {
            let arrLogsObj = try managedContext.fetch(requestDel)
            for logObj in arrLogsObj as! [NSManagedObject] {
                managedContext.delete(logObj)
            }
        } catch {
            print("Failed")
        }
        do {
            try managedContext.save()
        } catch {
            print("Failed saving")
        }
        
        //Inserting new log into DB
        let logEntity = NSEntityDescription.entity(forEntityName: "Logs", in: managedContext)!
        let log = NSManagedObject(entity: logEntity, insertInto: managedContext)
        
        log.setValue(currentTime, forKey: "timeStamp")
        log.setValue("Import Log Message from LXlogger", forKey: "message")
        log.setValue(false, forKey: "sent")

        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //changing the sent flag once it's been sent to the server
    func UpdateData() {
        let managedContext = persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Logs")
        fetchRequest.predicate = NSPredicate(format: "sent = %@", "false")
        
        do {
            let flagDown = try managedContext.fetch(fetchRequest)
            let objectUpdate = flagDown[0] as! NSManagedObject
            objectUpdate.setValue(true, forKey: "sent")
            
            do {
                try managedContext.save()
            }
            catch {
                print(error)
            }
        }
        catch {
            print(error)
        }
    }
    
    func DeleteAllData(){
        let managedContext = persistentContainer.viewContext
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Logs"))
        do {
            try managedContext.execute(DelAllReqVar)
        }
        catch {
            print(error)
        }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Logs")
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try managedContext.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "timeStamp") as! Double)
                print(data.value(forKey: "message") as! String)
                print(data.value(forKey: "sent") as! Bool)
            }
            
        } catch {
            
            print("Failed")
        }
        
    }
    
}
