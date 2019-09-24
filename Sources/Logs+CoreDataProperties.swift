//
//  Logs+CoreDataProperties.swift
//  HyperLogKit OSX
//
//  Created by Omer Younus on 2019-09-23.
//  Copyright © 2019 HyperLogKit. All rights reserved.
//

import Foundation
import CoreData

extension Logs {
    @NSManaged var sent: Bool
    @NSManaged var message: String
    @NSManaged var timeStamp: Double

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Logs> {
        return NSFetchRequest<Logs>(entityName: "Logs")
    }
}
