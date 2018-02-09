//
//  TaskCell.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class TaskCell: UITableViewCell {
    
    @IBOutlet var TaskField: UITextField!
    @IBOutlet var DateField: UILabel!
    
    @IBOutlet var LabelWrapper: UIView!
    @IBOutlet var LabelWrapperConstraint: NSLayoutConstraint!
    @IBOutlet var ImageLeftConstraint: NSLayoutConstraint!
    @IBOutlet var ImageRightConstraint: NSLayoutConstraint!
    @IBOutlet var Background: UIView!
    @IBOutlet var RecurringButton: UIButton!
    @IBOutlet var RemindButton: UIButton!
    @IBOutlet var whiteMark: UIImageView!
}

class AddCell: UITableViewCell {
    
    @IBOutlet var AddButton: UIButton!
    @IBOutlet var TaskField: UITextField!
    
}

class ListCell: UICollectionViewCell {
    
    
    @IBOutlet var ListField: UITextField!
    var intrinsicSize = CGSize(width: 60.0, height: 40.0)
    
}

class AddList: UICollectionViewCell {
    
}
