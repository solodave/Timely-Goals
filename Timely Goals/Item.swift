//
//  Item.swift
//  Timely Goals
//
//  Created by David Solomon on 1/4/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class Item: NSObject, NSCoding {
    
    var label : String
    var reminderDate: Date? = nil
    var isRecurring = false
    var recurrencePeriod = 0
    var recurrenceUnit = -1
    var daysOfWeek: [Int] = []
    var daysOfMonth: [Int] = []
    
    var id : Int = hash()

    
    init(label: String) {
        self.label = label
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(reminderDate, forKey: "reminderDate")
        aCoder.encode(id, forKey: "id")
        aCoder.encode(isRecurring, forKey: "isRecurring")
        aCoder.encode(recurrencePeriod, forKey: "recurrencePeriod")
        aCoder.encode(recurrenceUnit, forKey: "recurrenceUnit")
        aCoder.encode(daysOfWeek, forKey: "daysOfWeek")
        aCoder.encode(daysOfMonth, forKey: "daysOfMonth")

    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as! String
        reminderDate = aDecoder.decodeObject(forKey: "reminderDate") as? Date
        id = aDecoder.decodeInteger(forKey: "id")
        isRecurring = aDecoder.decodeBool(forKey: "isRecurring")
        recurrencePeriod = aDecoder.decodeInteger(forKey: "recurrencePeriod")
        recurrenceUnit = aDecoder.decodeInteger(forKey: "recurrenceUnit")
        daysOfWeek = aDecoder.decodeObject(forKey: "daysOfWeek") as! [Int]
        daysOfMonth = aDecoder.decodeObject(forKey: "daysOfMonth") as! [Int]

        super.init()
    }
}
