//
//  ViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {
    
    var isGrantedNotificationAccess:Bool = false
    
    var Items: ItemStore!
    var AllUnits = [[String]]()
    var DayUnits = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var WeekUnits = ["Every Week", "Every 2nd Week", "Every 3rd Week", "Every 4th Week"]
    var MonthUnits = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    var selectedUnit = 0
    var selectedCell = 0
    var dropCell : Int?
    var selectedTableCell = TaskCell()
    var isCreationCell = false
    
    var panAmount = CGFloat()
    var tempUnit = 0
    var tempCell = 0
    private var dragLabel: UILabel?
    var dragX = 0.0
    var dragY: CGFloat = 0.0
    var currX: Int = 0
    var currY: Int = 0
    var prevIncrement = 0
    var precisionTimer = Timer()
    var gregorian = Calendar(identifier: .gregorian)
    var components = DateComponents()
    
    var originalOrigin = CGPoint()
    var editingTextField : Bool = false
    var panLocation: CGPoint? = nil
    var originalConstant: CGFloat? = nil
    
    var blurEffectView: UIVisualEffectView!
    
    @IBOutlet var PanInstructions: UILabel!
    @IBOutlet var PanInstructionsXPosition: NSLayoutConstraint!
    
    @IBOutlet var tableBottom: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var DatePicker: UIDatePicker!
    
    @IBOutlet var DatePickerConstraint: NSLayoutConstraint!
    
    var tapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PanInstructions.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        AllUnits = [DayUnits, WeekUnits, MonthUnits]
        
        DatePicker.addTarget(self, action: #selector(updateDate), for: .valueChanged)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDatePicker))
        
        UNUserNotificationCenter.current().delegate = self

        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
            self.isGrantedNotificationAccess = granted
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (Items.itemLists.count > 0) {
            return Items.itemLists[selectedUnit].items.count + 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rows = tableView.numberOfRows(inSection: 0)
        
        if (indexPath.row == rows - 1) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCell", for: indexPath) as! AddCell
            cell.AddButton.addTarget(self, action: #selector(nameNewTask), for: .touchUpInside)
            cell.TaskField.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
            
            let item = Items.itemLists[selectedUnit].items[indexPath.row]
            cell.TaskField.text = item.label
            cell.TaskField.delegate = self
            
            cell.DateField.text = formatDate(wrappedDate: item.reminderDate)
            if let recurString = formatRecurrence(item: item) {
                if let date = cell.DateField.text {
                    cell.DateField.text = "\(date), \(recurString)"
                }
            }
            if item.reminderDate != nil && item.reminderDate! < Date() {
                cell.DateField.textColor = UIColor.red
            } else {
                cell.DateField.textColor = UIColor.black
            }
            
            cell.LabelWrapperConstraint.constant = 0
            cell.ImageLeftConstraint.isActive = true
            cell.ImageRightConstraint.isActive = false
        
            cell.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 150/255, alpha: 0.15)
            
            if (cell.contentView.gestureRecognizers?.count)! < 3 {
                let pan = UIPanGestureRecognizer(target: self, action:#selector(removeTask))
                pan.delegate = self
                cell.contentView.addGestureRecognizer(pan)
                
                let lpGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell))
                lpGestureRecognizer.minimumPressDuration = 1.0
                cell.contentView.addGestureRecognizer(lpGestureRecognizer)
                
                let swipeRightRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(showDatePicker))
                cell.contentView.addGestureRecognizer(swipeRightRecognizer)
                
                
            }

            if (item.reminderDate != nil) {
                cell.RecurringButton.isHidden = false
                
                if cell.RecurringButton.gestureRecognizers == nil {
                    let recurPan = UILongPressGestureRecognizer(target: self, action:#selector(makeRecurring))
                    recurPan.minimumPressDuration = 0.1
                    cell.RecurringButton.addGestureRecognizer(recurPan)
                }
                
                cell.RecurringButton.layer.cornerRadius = 5
                cell.RecurringButton.alpha = item.isRecurring ? 1.0 : 0.4
                cell.RecurringButton.addTarget(self, action: #selector(disableRecurrence), for: .touchUpInside)
            } else {
                cell.RecurringButton.isHidden = true
            }
            
            if cell.RemindButton.gestureRecognizers == nil {
                let remindPan = UILongPressGestureRecognizer(target: self, action:#selector(setTime))
                remindPan.minimumPressDuration = 0.1
                cell.RemindButton.addGestureRecognizer(remindPan)
            }
            
            cell.RemindButton.alpha = item.reminderDate != nil ? 1.0 : 0.4
            cell.RemindButton.layer.cornerRadius = 5
            cell.RemindButton.addTarget(self, action: #selector(disableReminder), for: .touchUpInside)
            
            
            return cell
        }
    }
    
    @objc func showDatePicker(recognizer: UIPinchGestureRecognizer) {
        selectedCell = tableCellCheck(recognizer: recognizer)
        selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
        DatePickerConstraint.constant = -250
        self.view.addGestureRecognizer(tapGesture)

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func dismissDatePicker(recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: view)
        if !DatePicker.frame.contains(point) {
            DatePickerConstraint.constant = 0
            self.view.removeGestureRecognizer(tapGesture)
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func updateDate() {
        let item = Items.itemLists[selectedUnit].items[selectedCell]
        item.reminderDate = DatePicker.date
        tableView.reloadRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
    }
    
    
    @objc func disableReminder(button: UIButton) {
        let cells = tableView.visibleCells
        for i in 0...cells.count - 1 {
            if cells[i].frame.contains(button.center) {
                selectedTableCell = cells[i] as! TaskCell
                if let path = tableView.indexPath(for: selectedTableCell) {
                    selectedCell = path.row
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    item.reminderDate = nil
                    item.recurrenceUnit = -1
                    item.recurrencePeriod = 0
                    item.isRecurring = false
                    
                    tableView.reloadRows(at: [path], with: .none)
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(Items.itemLists[selectedUnit].items[selectedCell].id)])
                    break
                }
            }
        }
    }
    
    @objc func disableRecurrence(button: UIButton) {
        let cells = tableView.visibleCells
        for i in 0...cells.count - 1 {
            if cells[i].frame.contains(button.center) {
                selectedTableCell = cells[i] as! TaskCell
                if let path = tableView.indexPath(for: selectedTableCell) {
                    selectedCell = path.row
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    item.recurrenceUnit = -1
                    item.recurrencePeriod = 0
                    item.isRecurring = false
                    
                    tableView.reloadRows(at: [path], with: .none)
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(Items.itemLists[selectedUnit].items[selectedCell].id)])
                    break
                }
            }
        }
    }
    
    @objc func nameNewTask(button: UIButton) {
        selectedCell = tableView.numberOfRows(inSection: 0) - 1
        tempCell = selectedCell
        let path = IndexPath(row: selectedCell, section: 0)
        let cell = tableView.cellForRow(at: path) as! AddCell
        isCreationCell = true
        if let field = cell.TaskField {
            field.isEnabled = true
            field.becomeFirstResponder()
        }
    }
    
    @objc func setTime(recognizer: UIPanGestureRecognizer) {
        let widthIncrement = UIScreen.main.bounds.width / 6
        let heightIncrement = UIScreen.main.bounds.height / 24
        
        currX = Int(floor(recognizer.location(in: view).x / widthIncrement))
        currY = Int(floor(recognizer.location(in: view).y / heightIncrement))
        
        
        switch recognizer.state {
        case .began:
            components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
            selectedCell = tableCellCheck(recognizer: recognizer)
            selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
            
            PanInstructions.isHidden = false
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 100
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            let dateString = formatDate(wrappedDate: item.reminderDate) ?? ""
            PanInstructions.text = "12 hours horizontal\n30 min vertical\n" + dateString
            tableView.alpha = 0.3
        case .changed:
            components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
            components.hour = components.hour! + (currX * 12) + (currY / 2)
            components.minute = (currY % 2) * 30
            components.second = 0
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            Items.itemLists[selectedUnit].items[selectedCell].reminderDate = gregorian.date(from: components)!
            selectedTableCell.DateField.text = formatDate(wrappedDate: item.reminderDate)
            tableView.reloadRows(at: [IndexPath(row: selectedCell, section:0)], with: .none)
            
            let dateString = formatDate(wrappedDate: item.reminderDate) ?? ""
            PanInstructions.text = "8 hours horizontal\n15 min vertical\n" + dateString
        case .ended:
            tableView.alpha = 1
            PanInstructions.isHidden = true
                let item = Items.itemLists[selectedUnit].items[selectedCell]
                selectedTableCell.DateField.text = formatDate(wrappedDate: item.reminderDate)
                tableView.reloadRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                if isGrantedNotificationAccess{
                    let seconds = item.reminderDate!.timeIntervalSince(Date())
                    print(seconds)
                    if (seconds > 0) {
                        //add notification code here
                        let content = UNMutableNotificationContent()
                        content.body = selectedTableCell.TaskField.text!
                        content.categoryIdentifier = String(item.id)
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                        let request = UNNotificationRequest(identifier: String(item.id), content: content, trigger: trigger)
                        
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                            for request in requests {
                                print("Request \(request.trigger)")
                            }
                        })
                    }
                }
            view.setNeedsDisplay()
            view.layoutIfNeeded()
            view.setNeedsLayout()
        case .cancelled:
            print("Cancelled?")
        default:
            print("Error?")
        }
    }
    
    @objc func makeRecurring(recognizer: UIPanGestureRecognizer) {
        selectedCell = tableCellCheck(recognizer: recognizer)
        selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
        
        let widthIncrement = UIScreen.main.bounds.width / 3
        let heightIncrement = UIScreen.main.bounds.height / 6
        
        currX = Int(floor(recognizer.location(in: view).x / widthIncrement))
        currY = Int(floor(recognizer.location(in: view).y / heightIncrement))
        let item = Items.itemLists[selectedUnit].items[selectedCell]
        
        switch recognizer.state {
        case .began:
            item.isRecurring = true
        case .changed:
            item.recurrenceUnit = 2 - currX
            item.recurrencePeriod = currY + 1
            
            PanInstructions.isHidden = false
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 100
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            if let recurString = formatRecurrence(item: item) {
                selectedTableCell.DateField.text = "\(formatDate(wrappedDate: item.reminderDate)!), \(recurString)"
                tableView.reloadRows(at: [IndexPath(row: selectedCell, section:0)], with: .none)
                PanInstructions.text = "Time Period Horizontal\nNumber Vertical\n\(recurString)"
                tableView.alpha = 0.3
            }
        case .ended:
            tableView.alpha = 1
            PanInstructions.isHidden = true
        default:
            break
        }
    }
    
    @objc func removeTask(recognizer: UIPanGestureRecognizer)
    {
        let panRightMax : CGFloat = 70.0
        let panLeftMax : CGFloat = -70.0
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

                let isPanAmountPositive = panAmount > 0
                selectedTableCell.ImageLeftConstraint.isActive = isPanAmountPositive
                selectedTableCell.ImageRightConstraint.isActive = !isPanAmountPositive
                
                if (isPanAmountPositive) {
                    selectedTableCell.Background.backgroundColor = .red
                    selectedTableCell.whiteMark.image = UIImage(named: "x")
                } else {
                    selectedTableCell.Background.backgroundColor = .green
                    selectedTableCell.whiteMark.image = UIImage(named: "checkmarkwhite")
                }
                
                let isLargePan = isPanAmountPositive ? panAmount > panRightMax : panAmount < panLeftMax
                UIView.animate(withDuration: 0.2) {
                    self.selectedTableCell.Background.alpha = isLargePan ? 1 : 0.5
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
                    let item = self.Items.itemLists[self.selectedUnit].items[self.selectedCell]
                    if item.isRecurring && self.panAmount < panLeftMax {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(item.id)])
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(item.id)])
                        
                        var unit: Calendar.Component
                        if item.recurrenceUnit == 0 {
                            unit = .day
                        } else if item.recurrenceUnit == 1 {
                            unit = .weekOfYear
                        } else {
                            unit = .month
                        }
                        item.reminderDate = Calendar.current.date(byAdding: unit, value: item.recurrencePeriod, to: item.reminderDate!)
                        self.selectedTableCell.LabelWrapperConstraint.constant = -edge
                        self.view.layoutIfNeeded()
                        self.selectedTableCell.LabelWrapperConstraint.constant = 0
                        UIView.animate(withDuration: 0.2, animations: { () -> Void in
                            self.view.layoutIfNeeded()
                        }, completion: { finished in
                            self.tableView.reloadRows(at: [IndexPath(row: self.selectedCell, section: 0)], with: .none)
                        })
                    } else {
                        self.Items.itemLists[self.selectedUnit].items.remove(at: self.selectedCell)
                        self.tableView.deleteRows(at: [IndexPath(row: self.selectedCell, section: 0)], with: .automatic)
                    }
                    
                    
                })
            } else {
                resetAfterPan()
            }
        case .cancelled:
            resetAfterPan()
        default:
            print("Default?")
        }
    }
    
    func resetAfterPan() {
        if let oriCon = originalConstant {
            selectedTableCell.LabelWrapperConstraint.constant = oriCon
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
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
                label.text = Items.itemLists[selectedUnit].items[selectedCell].label
                label.font = UIFont(name: "Kannada Sangam MN", size: 14.0)
                dragLabel = label
                dragX = Double((dragLabel?.center.x)! - 2.0)
                dragY = (dragLabel?.center.y)! - recognizer.location(in:view).y
                
                view.addSubview(dragLabel!)
                view.bringSubview(toFront: dragLabel!)

                originalOrigin = selectedTableCell.TaskField.convert(CGPoint.zero, to: view)
                
                UIView.animate(withDuration: 0.3) {
                    selectedTableCell.TaskField.center.y -= self.dragY
                    selectedTableCell.RecurringButton.alpha = 0.0
                    selectedTableCell.RemindButton.alpha = 0.0
                }
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
            
            var isIntersection = false
            for i in 0...Items.itemLists.count - 1 {
                let point = tableCollectionIntersect(it: i)
                if point != CGPoint.zero {
                    isIntersection = true
                    if (dropCell != i) {
                        let oldDropCell = dropCell
                        dropCell = i
                        if (oldDropCell != nil) {
                            collectionView.reloadItems(at: [IndexPath(row: oldDropCell!, section: 0)])
                        }
                        collectionView.reloadItems(at: [IndexPath(row: dropCell!, section: 0)])
                    }
                    break
                }
            }
            if !isIntersection && dropCell != nil {
                let oldDropCell = dropCell
                dropCell = nil
                collectionView.reloadItems(at: [IndexPath(row: oldDropCell!, section: 0)])
            }
            
            for i in 0...Items.itemLists[selectedUnit].items.count - 1 {
                let indexPath1 = IndexPath(row: i, section: 0)
                let indexPath2 = IndexPath(row: selectedCell, section: 0)
                let tableCell = tableView.cellForRow(at: indexPath1)!
                let newframe = originConverter(targetView: tableCell)
                
                if (newframe.contains(point)) {
                    if i == selectedCell {
                        return
                    }
                    tableView.beginUpdates()
                    Items.itemLists[selectedUnit].items.swapAt(selectedCell, i)
                    tableView.moveRow(at: indexPath1, to: indexPath2)
                    tableView.moveRow(at: indexPath2, to: indexPath1)
                    tableView.endUpdates()
                    
                    originalOrigin.y += tableCell.frame.height * (selectedCell > i ? -1 : 1)
                    selectedCell = i
                    break
                }
            }
        case .ended:
            if (dragLabel == nil) { return }
            let oldDropCell = dropCell
            dropCell = nil
            if let dCell = oldDropCell {
                collectionView.reloadItems(at: [IndexPath(row: dCell, section: 0)])
            }
            let selectedTableCell = tableView.cellForRow(at: IndexPath(row: selectedCell, section: 0)) as! TaskCell
            selectedTableCell.isHidden = false
            selectedTableCell.TaskField.isHidden = true
            
            var isIntersection = false
            for i in 0...Items.itemLists.count - 1 {
                let point = tableCollectionIntersect(it: i)
                if point != CGPoint.zero {
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    //item.modifiedDate = Date()
                    Items.itemLists[i].items.append(item)
                    Items.itemLists[selectedUnit].items.remove(at: selectedCell)
                    tableView.deleteRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.dragLabel?.transform = (self.dragLabel?.transform.scaledBy(x: 0.01, y: 0.01))!
                        self.dragLabel?.center = point
                    }, completion: { finished in
                        self.dragLabel?.removeFromSuperview()
                        self.dragLabel = nil
                        selectedTableCell.TaskField.isHidden = false
                        selectedTableCell.RecurringButton.alpha = 1.0
                        selectedTableCell.RemindButton.alpha = 1.0
                    })
                    isIntersection = true
                    break
                }
            }
            
            if (!isIntersection) {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.dragLabel?.frame.origin.y = self.originalOrigin.y
                    selectedTableCell.RecurringButton.alpha = 1.0
                    selectedTableCell.RemindButton.alpha = 1.0
                }, completion: { finished in
                    self.dragLabel?.removeFromSuperview()
                    self.dragLabel = nil
                    selectedTableCell.TaskField.isHidden = false
                })
            }
        default:
            print("Default?")
        }
    }
    
    @objc func listOptions (recognizer: UILongPressGestureRecognizer) {
        selectedUnit = collectionCellCheck(recognizer: recognizer)
        let cell = collectionView.cellForItem(at: IndexPath(item: selectedUnit, section:0)) as! ListCell
        
        let menu = UIMenuController.shared
        
            becomeFirstResponder()
        
            let renameItem = UIMenuItem(title: "Rename", action: #selector(renameList))
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteList))
        
            menu.menuItems = [renameItem, deleteItem]
            
            let targetRect = CGRect(x: cell.center.x, y: cell.frame.height + 10, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self.view)
            menu.setMenuVisible(true, animated: true)
        
        

    }
    @objc func renameList() {
        let cell = collectionView.cellForItem(at: IndexPath(item: selectedUnit, section:0)) as! ListCell
        cell.ListField.isEnabled = true
        cell.ListField.becomeFirstResponder()
    }
    
    @objc func deleteList() {
        Items.itemLists.remove(at: selectedUnit)
        collectionView.deleteItems(at: [IndexPath(item: selectedUnit, section:0)])
        if (selectedUnit > 0) {
            selectedUnit -= 1
        } else {
            selectedUnit = 0
        }
        collectionView.reloadData()
        tableView.reloadData()
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tempCell = indexPath.row
        if !editingTextField {
            selectedCell = indexPath.row
        }
        
        let rows = tableView.numberOfRows(inSection: 0)
        
        if (indexPath.row == rows - 1) {
            let cell = tableView.cellForRow(at: indexPath) as! AddCell
            isCreationCell = true
            if let field = cell.TaskField {
                field.isEnabled = true
                field.becomeFirstResponder()
            }
        } else {
            let cell = tableView.cellForRow(at: indexPath) as! TaskCell
            if let field = cell.TaskField {
                field.isEnabled = true
                field.becomeFirstResponder()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Items.itemLists.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cells = collectionView.numberOfItems(inSection: 0)
        
        if (indexPath.row == cells - 1) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddList", for: indexPath) as! AddList
            return cell
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath) as! ListCell
            cell.ListField.delegate = self
            cell.ListField.text = Items.itemLists[indexPath.row].label
            if (cell.ListField.text != nil && cell.ListField.text != "") {
                cell.ListField.isEnabled = false
            } else {
                cell.ListField.isEnabled = true
            }
            
            let lpGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(listOptions))
            lpGestureRecognizer.minimumPressDuration = 0.5
            cell.contentView.addGestureRecognizer(lpGestureRecognizer)
            
            UIView.animate(withDuration: 0.3) {
                cell.backgroundColor = UIColor.clear
            }
            cell.layer.borderWidth = indexPath.row == selectedUnit ? 1.0 : 0.0
            cell.layer.borderColor = indexPath.row == selectedUnit ? UIColor.blue.cgColor : UIColor.clear.cgColor

            if let dCell = dropCell, dCell == indexPath.row {
                UIView.animate(withDuration: 0.3) {
                    cell.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cells = collectionView.numberOfItems(inSection: 0)
        
        if (indexPath.row == cells - 1) {
            if (editingTextField) {
                return
            }
            Items.itemLists.append(ItemList(label:""))
            collectionView.insertItems(at: [indexPath])
            let cell = collectionView.cellForItem(at: indexPath) as! ListCell
            cell.ListField.becomeFirstResponder()
            tempUnit = selectedUnit
            selectedUnit = indexPath.row
        } else {
            tempUnit = indexPath.row
            if !editingTextField {
                selectedUnit = indexPath.row
            }
        
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
            tableView.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120.0, height: 40.0)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editingTextField = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // If tag is 99
        if (textField.tag == 99) {
            if let text = textField.text, text != "" {
                Items.itemLists[selectedUnit].label = textField.text!
                tempUnit = selectedUnit
                collectionView.reloadData()
                tableView.reloadData()
            } else {
                Items.itemLists.remove(at: selectedUnit)

                collectionView.deleteItems(at: [IndexPath(item:selectedUnit, section:0)])
                selectedUnit = tempUnit
                collectionView.reloadData()
            }
        } else {
            if let text = textField.text, text != "" {
                if isCreationCell {
                    selectedCell = tempCell
                    Items.itemLists[selectedUnit].items.insert(Item(label: text), at: selectedCell)
                    tableView.insertRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                    textField.text = nil
                } else {
                    Items.itemLists[selectedUnit].items[selectedCell].label = text
                }
            } else if !isCreationCell {
                Items.itemLists[selectedUnit].items.remove(at: selectedCell)
                tableView.deleteRows(at: [IndexPath(item:selectedCell, section:0)], with: .none)
            }
            
            selectedUnit = tempUnit
            selectedCell = tempCell

            isCreationCell = false
        }
        textField.isEnabled = false
        editingTextField = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        resignFirstResponder()
        return false
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.tag == 99) {
            return (textField.text?.count ?? 0) < 10 || string == ""
        }
        return true
    }
    
    func collectionCellCheck(recognizer: UIGestureRecognizer) -> Int {
        for i in 0...Items.itemLists.count - 1 {
            let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0))
            
            let recframe = originConverter(targetView: (recognizer.view)!)
            let newframe = originConverter(targetView: cell!)
            
            if (recframe.intersects(newframe)) {
                return i
            }
        }
        return -1
    }
    
    func tableCellCheck(recognizer: UIGestureRecognizer) -> Int {
        
        for i in 0...Items.itemLists[selectedUnit].items.count - 1 {
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
    
    func tableCollectionIntersect(it: Int) -> CGPoint {
        if (it == selectedUnit || it == 4) {
            return CGPoint.zero
        }
        let collectionCell = collectionView.cellForItem(at: IndexPath(item: it, section: 0))!
        let neworigin = collectionCell.convert(CGPoint.zero, to: view)
        var newframe = collectionCell.frame
        newframe.origin = neworigin
        if dragLabel!.frame.intersects(newframe) {
            newframe.origin.x += newframe.width / 2
            newframe.origin.y += newframe.height / 2
            return newframe.origin
        } else {
            return CGPoint.zero
        }
    }
    
    func formatDate(wrappedDate: Date?) -> String? {
        //Yesterday, today, tomorrow
        if let date = wrappedDate {
            let gregorian = Calendar(identifier: .gregorian)
            let dateComponents = gregorian.dateComponents([.day], from: date)
            let todayComponents = gregorian.dateComponents([.day], from: Date())
            let day = dateComponents.day!
            let today = todayComponents.day!
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short

            if today > day - 2 && today < day + 2 {
                dateFormatter.dateStyle = .none
                let dayString : String
                if (today == day + 1) {
                    dayString = "Yesterday"
                } else if (today == day) {
                    dayString = "Today"
                } else {
                    dayString = "Tomorrow"
                }
                return dayString + ", " + dateFormatter.string(from: date)
            } else {
                dateFormatter.dateStyle = .short
                return dateFormatter.string(from: date)
            }
        } else {
            return nil
        }
    }
    
    func formatRecurrence(item: Item) -> String? {
        let recur = item.recurrenceUnit
        let period = item.recurrencePeriod
        if recur == 0 {
            if period == 1 {
                return "Daily"
            } else {
                return "Every \(period) Days"
            }
        } else if recur == 1 {
            if period == 1 {
                return "Weekly"
            } else {
                return "Every \(period) Weeks"
            }
        } else if recur == 2 {
            if period == 1 {
                return "Monthly"
            } else {
                return "Every \(period) Months"
            }
        } else {
            return nil
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                tableBottom.constant = -keyboardSize.height
                self.view.layoutIfNeeded()
            }
        }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableBottom.constant = 0
        self.view.layoutIfNeeded()
    }
}
