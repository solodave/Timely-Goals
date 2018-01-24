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
    var modifiedDate = Date()
    var oldPosition: Int = -1
    var recurrenceArray : [Bool] = Array(repeating: false, count: 12)
    
    init(label: String) {
        self.label = label
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(isDoneForNow, forKey: "isDoneForNow")
        aCoder.encode(modifiedDate, forKey: "modifiedDate")
        aCoder.encode(oldPosition, forKey: "oldPosition")
    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as! String
        isDoneForNow = aDecoder.decodeBool(forKey: "isDoneForNow")
        modifiedDate = aDecoder.decodeObject(forKey: "modifiedDate") as! Date
        oldPosition = aDecoder.decodeInteger(forKey: "oldPosition")
        
        super.init()
    }
    
    func isRecurring() -> Bool {
        for i in recurrenceArray {
            if (i) {
                return true
            }
        }
        return false
    }
    
}
