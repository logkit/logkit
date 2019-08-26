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

public class LXDataBaseEndpoint: LXEndpoint {
    
    /// The minimum Priority Level a Log Entry must meet to be accepted by this Endpoint.
    public var minimumPriorityLevel: LXPriorityLevel
    /// The formatter used by this Endpoint to serialize a Log Entry’s `dateTime` property to a string.
    public var dateFormatter: LXDateFormatter
    /// The formatter used by this Endpoint to serialize each Log Entry to a string.
    public var entryFormatter: LXEntryFormatter
    /// This Endpoint requires a newline character appended to each serialized Log Entry string.
    public let requiresNewlines: Bool = true

    lazy var persistentContainer: NSPersistentContainer = {
        let messageKitBundle = Bundle(identifier: "info.logkit.LogKit")
        let modelURL = messageKitBundle!.url(forResource: "LogKit", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        let container = NSPersistentContainer(name: "LogKit", managedObjectModel: managedObjectModel!)
 
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                NSLog("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext(managedContext: NSManagedObjectContext) {

        if managedContext.hasChanges {
            do {
                try managedContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func createData(data: Data){
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
            NSLog("Failed to delete old data")
        }
        saveContext(managedContext: managedContext)
        
        //Inserting new log into DB
        let logEntity = NSEntityDescription.entity(forEntityName: "Logs", in: managedContext)!
        let log = NSManagedObject(entity: logEntity, insertInto: managedContext)
        let logMsg = String(decoding: data, as: UTF8.self)
        
        log.setValue(currentTime, forKey: "timeStamp")
        log.setValue(logMsg, forKey: "message")
        log.setValue(false, forKey: "sent")

        saveContext(managedContext: managedContext)

    }
    
    //changing the sent flag once it's been sent to the server
    func updateData() {
        let managedContext = persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Logs")
        fetchRequest.predicate = NSPredicate(format: "sent = %@", "false")
        
        do {
            let flagDown = try managedContext.fetch(fetchRequest)
            let objectUpdate = flagDown[0] as! NSManagedObject
            objectUpdate.setValue(true, forKey: "sent")
            
            saveContext(managedContext: managedContext)
        }
        catch {
            NSLog("Fail to update sent flags, \(error)")
        }
    }
  
    public init(
        minimumPriorityLevel: LXPriorityLevel = .All,
        dateFormatter: LXDateFormatter = LXDateFormatter.standardFormatter(),
        entryFormatter: LXEntryFormatter = LXEntryFormatter.standardFormatter()
        ) {
        self.minimumPriorityLevel = minimumPriorityLevel
        self.dateFormatter = dateFormatter
        self.entryFormatter = entryFormatter
    }

    public func write(string: String) {
        guard let data = string.data(using: String.Encoding.utf8) else {
            assertionFailure("Failure to create data from entry string")
            return
        }
        LK_LOGKIT_QUEUE.async {
            self.createData(data: data)
        }
    }
}
