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
    var isDoneForNow : Bool = false
    var reminderDate: Date? = nil
    var oldPosition: Int = -1
    var id : Int = hash()
    
    
    init(label: String) {
        self.label = label
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(isDoneForNow, forKey: "isDoneForNow")
        aCoder.encode(reminderDate, forKey: "reminderDate")
        aCoder.encode(oldPosition, forKey: "oldPosition")
        aCoder.encode(id, forKey: "id")
    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as! String
        isDoneForNow = aDecoder.decodeBool(forKey: "isDoneForNow")
        reminderDate = aDecoder.decodeObject(forKey: "reminderDate") as? Date
        oldPosition = aDecoder.decodeInteger(forKey: "oldPosition")
        id = aDecoder.decodeInteger(forKey: "id")
        
        super.init()
    }
    
    func isRecurring() -> Bool {
        return true
    }
    
}
