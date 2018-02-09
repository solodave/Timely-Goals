//
//  ItemList.swift
//  Timely Goals
//
//  Created by David Solomon on 2/9/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import Foundation

class ItemList: NSObject, NSCoding {
    
    var items: [Item] = []
    var label: String = ""
    
    init(label: String) {
        self.label = label
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(items, forKey: "items")
    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as! String
        items = aDecoder.decodeObject(forKey: "items") as! [Item]
        
        super.init()
    }
    
}
