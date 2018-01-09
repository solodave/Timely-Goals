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

    @IBOutlet var LabelWrapper: UIView!
    @IBOutlet var LabelWrapperConstraint: NSLayoutConstraint!
    @IBOutlet var ImageLeftConstraint: NSLayoutConstraint!
    @IBOutlet var ImageRightConstraint: NSLayoutConstraint!
    @IBOutlet var Background: UIView!
    @IBOutlet var ButtonWrapper: UIView!
}

class TimeUnitCell: UICollectionViewCell {
    
    
    @IBOutlet var TimeUnitLabel: UILabel!
    
}
