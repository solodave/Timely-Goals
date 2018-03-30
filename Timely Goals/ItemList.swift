//
//  ItemList.swift
//  Timely Goals
//
//  Created by David Solomon on 2/9/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import Foundation
import UIKit

class ItemList: NSObject, NSCoding {
    
    
    static var colors = [UIColor.blue, UIColor.orange, UIColor.purple, UIColor.brown, UIColor.magenta, UIColor.darkGray]
    var items: [Item] = []
    var label: String = ""
    var color: UIColor = UIColor()
    
    init(label: String) {
        
        self.label = label
        
        let it = UserDefaults.standard.integer(forKey: "currentColor")
        
        self.color = ItemList.colors[it]
        UserDefaults.standard.set((it + 1) % 6, forKey: "currentColor")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(label, forKey: "label")
        aCoder.encode(items, forKey: "items")
        aCoder.encode(color, forKey: "color")
    }
    
    required init(coder aDecoder: NSCoder) {
        label = aDecoder.decodeObject(forKey: "label") as? String ?? "Unnamed list"
        items = aDecoder.decodeObject(forKey: "items") as? [Item] ?? []
        color = aDecoder.decodeObject(forKey: "color") as? UIColor ?? ItemList.colors[Int(arc4random_uniform(6))]
        
        super.init()
    }
    
}
