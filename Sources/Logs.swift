//
//  Logs.swift
//  HyperLogKit OSX
//
//  Created by omer on 2019-09-16.
//  Copyright © 2019 HyperLogKit. All rights reserved.
//

import Foundation
import CoreData

@objc(Logs)
class Logs: NSManagedObject {
    
    @NSManaged var sent: Bool
    @NSManaged var message: String
    @NSManaged var timeStamp: long
    
}
