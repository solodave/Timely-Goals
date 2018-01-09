//
//  ViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var highlightCellAtBeginning = false
    
    var Items: [[Item]] = [[],[],[],[]]
    var TimeUnits = ["Daily", "Weekly", "Monthly", "Yearly"]
    
    var selectedUnit = 0
    var selectedCell = 0
    var selectedTableCell = TaskCell()
    var panAmount = CGFloat()
    var tempUnit = 0
    private var dragLabel: UILabel?
    var dragX = 0.0
    
    var oldPoint = CGPoint()
    var oldHeight : CGFloat = 0.0
    var oldWidth : CGFloat = 0.0
    
    var previousIndexPath : IndexPath? = nil
    var editingTextField : Bool = false
    var panLocation: CGPoint? = nil
    var originalConstant: CGFloat? = nil
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 65

        collectionView.delegate = self
        collectionView.dataSource = self
    }

    
    @IBAction func addNewItem(_ sender: Any) {
        
        let item = Item(label: "New task")
        let index = Items[selectedUnit].count
        
        Items[selectedUnit].append(item)
        let indexPath = IndexPath(row: index, section: 0)

        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return Items[selectedUnit].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        
        let item = Items[selectedUnit][indexPath.row]
        cell.TaskField.text = item.label
        cell.TaskField.placeholder = String(indexPath.row)
        cell.TaskField.delegate = self
        cell.LabelWrapperConstraint.constant = 0
        cell.ImageLeftConstraint.isActive = true
        cell.ImageRightConstraint.isActive = false
        
        let lpGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell))
        
        // Method of identifying cells
        cell.contentView.addGestureRecognizer(lpGestureRecognizer)
        
        let pan = UIPanGestureRecognizer(target: self, action:#selector(removeTask))
        pan.delegate = self
        cell.contentView.addGestureRecognizer(pan)
        
        cell.RecurringButton.alpha = item.isRecurring ? 1.0 : 0.2
        
        cell.RecurringButton.layer.cornerRadius = 5
        cell.RecurringButton.addTarget(self, action: #selector(makeRecurring), for: .touchUpInside)
        cell.RecurringButton.tag = indexPath.row

        return cell
    }
    
    @objc func makeRecurring(button: UIButton) {
        
        let path = IndexPath(row: button.tag, section: 0)
    
        Items[selectedUnit][path.row].isRecurring = !Items[selectedUnit][path.row].isRecurring
        button.alpha = Items[selectedUnit][path.row].isRecurring ? 1.0 : 0.2
        

    }
    
    @objc func removeTask(recognizer: UIPanGestureRecognizer)
    {
        let panRightMax : CGFloat = 50.0
        let panLeftMax : CGFloat = -50.0
        switch recognizer.state {
        case .began:
            if (recognizer.view != nil) {
                view.endEditing(true)
                selectedCell = tableCellCheck(recognizer: recognizer)
                selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
                originalConstant = selectedTableCell.LabelWrapperConstraint.constant
                selectedTableCell.Background.alpha = 0.5
                panLocation = recognizer.location(in: view)
            } else {
                recognizer.isEnabled = false
                recognizer.isEnabled = true
            }
        case .changed:
            if let panLoc = panLocation {
                panAmount = recognizer.location(in: view).x - panLoc.x
                
                
                
                if (panAmount > 0) {
                    selectedTableCell.ImageLeftConstraint.isActive = true
                    selectedTableCell.ImageRightConstraint.isActive = false
                    if panAmount > panRightMax {
                        UIView.animate(withDuration: 0.2) {
                            self.selectedTableCell.Background.alpha = 1
                        }
                    } else {
                        UIView.animate(withDuration: 0.2) {
                            self.selectedTableCell.Background.alpha = 0.5
                        }
                    }
                } else {
                    selectedTableCell.ImageLeftConstraint.isActive = false
                    selectedTableCell.ImageRightConstraint.isActive = true
                    if panAmount < panLeftMax {
                        UIView.animate(withDuration: 0.2) {
                            self.selectedTableCell.Background.alpha = 1
                        }
                    } else {
                        UIView.animate(withDuration: 0.2) {
                            self.selectedTableCell.Background.alpha = 0.5
                        }
                    }
                }
            }
            selectedTableCell.LabelWrapperConstraint.constant = panAmount
        case .ended:
            panLocation = nil
            if (panAmount > panRightMax || panAmount < panLeftMax) {
                let edge = panAmount > panRightMax ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width
                selectedTableCell.LabelWrapperConstraint.constant = edge
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                }, completion: { finished in
                    self.Items[self.selectedUnit].remove(at: self.selectedCell)
                    self.tableView.deleteRows(at: [IndexPath(row: self.selectedCell, section: 0)], with: .automatic)
                    //self.tableView.reloadData()
                })
            } else {
                if let oriCon = originalConstant {
                    selectedTableCell.LabelWrapperConstraint.constant = oriCon
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
        case .cancelled:
            if let oriCon = originalConstant {
                selectedTableCell.LabelWrapperConstraint.constant = oriCon
                UIView.animate(withDuration: 0.2) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            print("Default?")
        }
    }
    
    @objc func didLongPressCell (recognizer: UILongPressGestureRecognizer) {
       
        
        switch recognizer.state {
        case .began:
            view.endEditing(true)
            if recognizer.view != nil  {
            
                selectedCell = tableCellCheck(recognizer: recognizer)
                
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = Items[selectedUnit][selectedCell].label
                dragLabel = label
                dragX = Double((dragLabel?.center.x)! + 50)
                
                view.addSubview(dragLabel!)
                view.bringSubview(toFront: dragLabel!)
                dragLabel?.center = recognizer.location(in: view)
                
                let selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0))
                selectedTableCell?.isHidden = true
                
                view.setNeedsDisplay()
                print("Begin")
            }
        case .changed:
            let point = recognizer.location(in: view)
            let tView = originConverter(targetView: tableView)
            if tView.contains(point) {
                dragLabel?.center.y = recognizer.location(in: view).y
                dragLabel?.center.x = CGFloat(dragX)
            } else {
                dragLabel?.center = recognizer.location(in: view)
            }
            
            for i in 0...Items[selectedUnit].count - 1 {
                let indexPath1 = IndexPath(row: i, section: 0)
                let indexPath2 = IndexPath(row: selectedCell, section: 0)
                let tableCell = tableView.cellForRow(at: indexPath1)
                let newframe = originConverter(targetView: tableCell!)
                
                if (newframe.contains(point)) {
                    print("\(i) \(selectedCell)")
                    if i == selectedCell {
                        return
                    }
                    tableView.beginUpdates()
                    let movedItem = Items[selectedUnit][selectedCell]
                    Items[selectedUnit].remove(at: selectedCell)
                    Items[selectedUnit].insert(movedItem, at: i)
                    tableView.moveRow(at: indexPath1, to: indexPath2)
                    tableView.moveRow(at: indexPath2, to: indexPath1)
                    tableView.endUpdates()
                    selectedCell = i
                    break
                }
            }
            
            let checkResult = tableCellCheck(recognizer: recognizer)
            print(checkResult)
            if (checkResult != -1) {
                
            }
        case .ended:
            if (dragLabel == nil) { return }
            
            
            var isIntersection = false
            for i in 0...TimeUnits.count - 1 {
                if (i == selectedUnit) {
                    continue
                }
                let collectionCell = collectionView.cellForItem(at: IndexPath(item: i, section: 0))!
                let neworigin = collectionCell.convert(CGPoint.zero, to: view)
                var newframe = collectionCell.frame
                newframe.origin = neworigin
                
                
                if dragLabel!.frame.intersects(newframe) {
                    let item = Items[selectedUnit][selectedCell]
                    Items[i].append(item)
                    print("i is \(i)")
                    Items[selectedUnit].remove(at: selectedCell)
                    tableView.deleteRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                    
                    dragLabel?.removeFromSuperview()
                    dragLabel = nil
                    isIntersection = true
                    
                    break
                }
            }
            
            if (!isIntersection) {
                dragLabel?.isHidden = true
                dragLabel?.removeFromSuperview()
                dragLabel = nil
                
                // Only way to force refresh of table given the setup
                let item = Item(label: "Dummy")
                Items[selectedUnit].append(item)
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                Items[selectedUnit].removeLast()
                tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)

            }
            tableView.reloadData()
        default:
            print("Default?")
            
        }
        
    }
    
    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            self.Items[selectedUnit].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
 
    }*/
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedCell = indexPath.row
        
        let cell = tableView.cellForRow(at: indexPath) as! TaskCell
        if let field = cell.TaskField {
            field.isEnabled = true
            field.becomeFirstResponder()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return TimeUnits.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeUnitCell", for: indexPath) as! TimeUnitCell
        
        cell.TimeUnitLabel.text = TimeUnits[indexPath.row]
        
        if (indexPath.row == 0 && !highlightCellAtBeginning) {
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.blue.cgColor
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        tempUnit = indexPath.row
        if !editingTextField {
            selectedUnit = indexPath.row
        }
        
        if let oldpath = previousIndexPath {
            let oldcell = collectionView.cellForItem(at: oldpath)
        
            oldcell?.layer.borderWidth = 0.0
            oldcell?.layer.borderColor = UIColor.clear.cgColor
        }
        
        let cell = collectionView.cellForItem(at: indexPath)

        cell?.layer.borderWidth = 1.0
        cell?.layer.borderColor = UIColor.blue.cgColor
        
        collectionView.reloadItems(at: [indexPath])
        previousIndexPath = indexPath
        tableView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        let count = CGFloat(TimeUnits.count)
        let width : CGFloat = UIScreen.main.bounds.width
        let totalcontentwidth : CGFloat = 60.0 * count
       return (width - totalcontentwidth) / count
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

        editingTextField = true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        let cell = Int(textField.placeholder!)!
        
        if let text = textField.text {
            Items[selectedUnit][cell].label = text
            tableView.reloadRows(at: [IndexPath(row: cell, section: 0)], with: .none)
        }
        
        textField.isEnabled = false
        selectedUnit = tempUnit
        editingTextField = false
        
    }
    
    func tableCellCheck(recognizer: UIGestureRecognizer) -> Int {
        
        for i in 0...Items[selectedUnit].count - 1 {
            let tableCell = tableView.cellForRow(at: IndexPath(item: i, section: 0))
            
            let recframe = originConverter(targetView: (recognizer.view)!)
            let newframe = originConverter(targetView: tableCell!)
            
            if (recframe.intersects(newframe)) {
                return i
            }
        }
        
        return -1
        
    }
    
    func originConverter(targetView: UIView) -> CGRect {
        var frame = targetView.frame
        let origin = targetView.convert(CGPoint.zero, to: view)
        frame.origin = origin
        return frame
    }
    
    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        if (g.isKind(of: UIPanGestureRecognizer.self)) {
            let t = (g as! UIPanGestureRecognizer).translation(in: view)
            let verticalness = abs(t.y)
            if (verticalness > 0) {
                print("ignore vertical motion in the pan ...")
                print("the event engine will >pass on the gesture< to the scroll view")
                return false
            }
        }
        return true
    }
    
}

