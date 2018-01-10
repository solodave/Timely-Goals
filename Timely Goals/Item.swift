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
    var isRecurring : Bool = false
    var isDoneForNow : Bool = false
    var modifiedDate = Date()
    var oldPosition: Int = -1
    
    init(label: String) {
        self.label = label
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(isRecurring, forKey: "isRecurring")
        aCoder.encode(isDoneForNow, forKey: "isDoneForNow")
        aCoder.encode(modifiedDate, forKey: "modifiedDate")
        aCoder.encode(oldPosition, forKey: "oldPosition")
    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as! String
        isRecurring = aDecoder.decodeBool(forKey: "isRecurring")
        isDoneForNow = aDecoder.decodeBool(forKey: "isDoneForNow")
        modifiedDate = aDecoder.decodeObject(forKey: "modifiedDate") as! Date
        oldPosition = aDecoder.decodeInteger(forKey: "oldPosition")
        
        super.init()
    }
    
    /*func getWeekday() -> Int {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: self.creationDate)
        return dayOfWeek
    }
    
    func getWeekdayOrdinal() -> Int {
        
        let calendar = Calendar.current
        let weekdayOrdinal = calendar.component(.weekdayOrdinal, from: self.creationDate)
        return weekdayOrdinal
    }*/
    
}
