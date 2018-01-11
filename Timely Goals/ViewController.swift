//
//  ViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var Items: ItemStore!
    
    var highlightCellAtBeginning = false
    
    
    var TimeUnits = ["Day", "Week", "Month", "Year", "Old"]
    
    var selectedUnit = 0
    var selectedCell = 0
    var selectedTableCell = TaskCell()
    var panAmount = CGFloat()
    var tempUnit = 0
    var tempCell = 0
    private var dragLabel: UILabel?
    var dragX = 0.0
    var dragY :CGFloat = 0.0
    
    var oldPoint = CGPoint()
    var oldHeight : CGFloat = 0.0
    var oldWidth : CGFloat = 0.0
    var originalOrigin = CGPoint()
    
    var previousIndexPath : IndexPath = IndexPath(row: 0, section: 0)
    var editingTextField : Bool = false
    var panLocation: CGPoint? = nil
    var originalConstant: CGFloat? = nil
    
    @IBOutlet var AddNewItemButton: UIBarButtonItem!
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
        
        if selectedUnit == 4 {
            return
        }
        
        let item = Item(label: "New task")
        
        Items.items[selectedUnit].insert(item, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)

        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var itemCount = 0
        for item in Items.items[selectedUnit] {
            if !item.isDoneForNow {
                itemCount += 1
            }
        }
        return itemCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        
        let item = Items.items[selectedUnit][indexPath.row]
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
    
        Items.items[selectedUnit][path.row].isRecurring = !Items.items[selectedUnit][path.row].isRecurring
        button.alpha = Items.items[selectedUnit][path.row].isRecurring ? 1.0 : 0.2
        

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
                    self.Items.items[self.selectedUnit][self.selectedCell].isDoneForNow = true
                    if self.Items.items[self.selectedUnit][self.selectedCell].isRecurring {
                        let item = self.Items.items[self.selectedUnit][self.selectedCell]
                        item.oldPosition = self.selectedCell
                        self.Items.items[self.selectedUnit + 5].append(item)
                    }
                    self.Items.items[self.selectedUnit].remove(at: self.selectedCell)
                    
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
                let selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
                let textFrame = originConverter(targetView: selectedTableCell.TaskField)

                
                let label = UILabel(frame: textFrame)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = Items.items[selectedUnit][selectedCell].label
                label.font = UIFont.systemFont(ofSize: 14.0)
                dragLabel = label
                dragX = Double((dragLabel?.center.x)! - 2.0)
                dragY = (dragLabel?.center.y)! - recognizer.location(in:view).y
                
                view.addSubview(dragLabel!)
                view.bringSubview(toFront: dragLabel!)

                originalOrigin = selectedTableCell.TaskField.convert(CGPoint.zero, to: view)

                print("DDDDD \(dragLabel?.center.y) \(recognizer.location(in:view))")
                
                UIView.animate(withDuration: 0.3) {
                    selectedTableCell.TaskField.center.y -= self.dragY
                    selectedTableCell.ButtonWrapper.alpha = 0.0
                }
                
                view.setNeedsDisplay()
            }
        case .changed:
            let point = recognizer.location(in: view)
            let selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell

            if (!selectedTableCell.isHidden) {
                selectedTableCell.isHidden = true
                selectedTableCell.TaskField.center.y += self.dragY
                self.dragLabel?.center.y = recognizer.location(in: self.view).y
                self.dragLabel?.center.x = CGFloat(self.dragX)
            } else {
                let tView = originConverter(targetView: tableView)
                if tView.contains(point) {
                    UIView.animate(withDuration: 0.1) {
                        self.dragLabel?.center.y = recognizer.location(in: self.view).y
                        self.dragLabel?.center.x = CGFloat(self.dragX)
                    }
                } else {
                    UIView.animate(withDuration: 0.1) {
                        self.dragLabel?.center = recognizer.location(in: self.view)
                    }
                }
            }
            for i in 0...Items.items[selectedUnit].count - 1 {
                let indexPath1 = IndexPath(row: i, section: 0)
                let indexPath2 = IndexPath(row: selectedCell, section: 0)
                let tableCell = tableView.cellForRow(at: indexPath1)!
                let newframe = originConverter(targetView: tableCell)
                
                if (newframe.contains(point)) {
                    print("\(i) \(selectedCell)")
                    if i == selectedCell {
                        return
                    }
                    tableView.beginUpdates()
                    let movedItem = Items.items[selectedUnit][selectedCell]
                    Items.items[selectedUnit].remove(at: selectedCell)
                    Items.items[selectedUnit].insert(movedItem, at: i)
                    tableView.moveRow(at: indexPath1, to: indexPath2)
                    tableView.moveRow(at: indexPath2, to: indexPath1)
                    tableView.endUpdates()
                    
                    if selectedCell > i {
                        originalOrigin.y -= tableCell.frame.height
                    } else {
                        originalOrigin.y += tableCell.frame.height
                    }
                    
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
            let selectedTableCell = tableView.cellForRow(at: IndexPath(row: selectedCell, section: 0)) as! TaskCell
            selectedTableCell.isHidden = false
            selectedTableCell.TaskField.isHidden = true
            
            var isIntersection = false
            for i in 0...TimeUnits.count - 1 {
                if (i == selectedUnit || i == 4) {
                    continue
                }
                let collectionCell = collectionView.cellForItem(at: IndexPath(item: i, section: 0))!
                let neworigin = collectionCell.convert(CGPoint.zero, to: view)
                var newframe = collectionCell.frame
                newframe.origin = neworigin
                
                
                if dragLabel!.frame.intersects(newframe) {
                    let item = Items.items[selectedUnit][selectedCell]
                    item.modifiedDate = Date()
                    Items.items[i].append(item)
                    Items.items[selectedUnit].remove(at: selectedCell)
                    tableView.deleteRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.dragLabel?.transform = (self.dragLabel?.transform.scaledBy(x: 0.01, y: 0.01))!
                        newframe.origin.x += newframe.width / 2
                        newframe.origin.y += newframe.height / 2
                        self.dragLabel?.center = newframe.origin
                        selectedTableCell.ButtonWrapper.alpha = 1.0
                    }, completion: { finished in
                        self.dragLabel?.removeFromSuperview()
                        self.dragLabel = nil
                        selectedTableCell.TaskField.isHidden = false
                    })
                    

                    isIntersection = true
                    
                    break
                }
            }
            
            if (!isIntersection) {
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.dragLabel?.frame.origin.y = self.originalOrigin.y
                    selectedTableCell.ButtonWrapper.alpha = 1.0
                }, completion: { finished in
                    
                    self.dragLabel?.isHidden = true
                    self.dragLabel?.removeFromSuperview()
                    self.dragLabel = nil
                    selectedTableCell.TaskField.isHidden = false
                    
                    // Only way to force refresh of table given the setup
                    let item = Item(label: "Dummy")
                    self.Items.items[self.selectedUnit].append(item)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    self.Items.items[self.selectedUnit].removeLast()
                    self.tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    self.tableView.reloadData()
                })


            }
        default:
            print("Default?")
            
        }
        
    }
    
    /*func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            self.Items.items[selectedUnit].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
 
    }*/
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tempCell = indexPath.row
        if !editingTextField {
            selectedCell = indexPath.row
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! TaskCell
        if let field = cell.TaskField {
            field.isEnabled = true
            field.becomeFirstResponder()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Items.items[4].count > 0 ? 5 : 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeUnitCell", for: indexPath) as! TimeUnitCell
        
        cell.TimeUnitLabel.text = TimeUnits[indexPath.row]
        
        if (indexPath.row == 4) {
            cell.TimeUnitLabel.textColor = UIColor.red
        } else {
            cell.TimeUnitLabel.textColor = UIColor.black
        }
        if (indexPath.row == selectedUnit) {
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.blue.cgColor
        } else {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if (indexPath.row == 4) {
            AddNewItemButton.isEnabled = false
            AddNewItemButton.tintColor = UIColor.clear
        } else {
            AddNewItemButton.isEnabled = true
            AddNewItemButton.tintColor = nil
        }
        tempUnit = indexPath.row
        if !editingTextField {
            selectedUnit = indexPath.row
        }
        
        let oldcell = collectionView.cellForItem(at: previousIndexPath)!
        
        oldcell.layer.borderWidth = 0.0
        oldcell.layer.borderColor = UIColor.clear.cgColor
        
        let cell = collectionView.cellForItem(at: indexPath)!

        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.blue.cgColor
        
        collectionView.reloadItems(at: [previousIndexPath, indexPath])
        previousIndexPath = indexPath
        tableView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        let count = CGFloat(Items.items[4].count > 0 ? 5 : 4)
        let width : CGFloat = collectionView.frame.width
        let totalcontentwidth : CGFloat = 45.0 * count
       return (width - totalcontentwidth) / count
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {

        editingTextField = true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let text = textField.text {
            Items.items[selectedUnit][selectedCell].label = text
           // tableView.reloadRows(at: [IndexPath(row: cell, section: 0)], with: .none)
        }
        
        textField.isEnabled = false
        selectedUnit = tempUnit
        selectedCell = tempCell
        editingTextField = false
        
    }
    
    func tableCellCheck(recognizer: UIGestureRecognizer) -> Int {
        
        for i in 0...Items.items[selectedUnit].count - 1 {
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
                return false
            }
        }
        return true
    }
    
}

