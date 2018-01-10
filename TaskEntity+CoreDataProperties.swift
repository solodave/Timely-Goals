//
//  TaskEntity+CoreDataProperties.swift
//  Timely Goals
//
//  Created by David Solomon on 1/10/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//
//

import Foundation
import CoreData


extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var label: String?
    @NSManaged public var timeUnit: Int16
    @NSManaged public var isDoneForNow: Bool
    @NSManaged public var isRecurring: Bool
    @NSManaged public var creationDate: NSDate?

}
