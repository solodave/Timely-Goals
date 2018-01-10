//
//  ItemStore.swift
//  Timely Goals
//
//  Created by David Solomon on 1/10/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class ItemStore {
    
    var items : [[Item]] = Array(repeating: [], count: 9)
    let itemArchiveURL: URL = {
        let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentsDirectories.first!
        return documentDirectory.appendingPathComponent("items.archive")
    }()
    
    init() {
        if let archivedItems = NSKeyedUnarchiver.unarchiveObject(withFile: itemArchiveURL.path)as? [[Item]] {
            items = archivedItems
        }
    }
    
    func saveChanges() -> Bool {
        return NSKeyedArchiver.archiveRootObject(items, toFile: itemArchiveURL.path)
    }
}
