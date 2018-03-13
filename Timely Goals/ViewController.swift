//
//  ViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit
import UserNotifications
import GoogleMobileAds
import StoreKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate, UNUserNotificationCenterDelegate {
    
    var bannerView: GADBannerView!
    var bannerViewHeight: CGFloat = 0.0
    
    var isGrantedNotificationAccess:Bool = false
    var collectionViewMenuMode: Bool = false
    
    var Items: ItemStore!
    
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
    var gregorian = Calendar(identifier: .gregorian)
    var components = DateComponents()
    
    var originalOrigin = CGPoint()
    var editingTextField : Bool = false
    var panLocation: CGPoint? = nil
    var originalConstant: CGFloat? = nil
    
    
    @IBOutlet var PanInstructions: UILabel!
    @IBOutlet var PanInstructionsXPosition: NSLayoutConstraint!
    
    @IBOutlet var tableBottom: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var bufferView: UIView!
    @IBOutlet var DatePicker: UIDatePicker!
    
    @IBOutlet var DatePickerConstraint: NSLayoutConstraint!
    
    var tapGesture: UITapGestureRecognizer!
    var dragTopConstraint = NSLayoutConstraint()
    var dragLeadingConstraint = NSLayoutConstraint()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PanInstructions.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        collectionView.delegate = self
        collectionView.dataSource = self
        
        DatePicker.addTarget(self, action: #selector(updateDate), for: .valueChanged)
        DatePicker.isHidden = true
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissDatePicker))
        tapGesture.cancelsTouchesInView = true
        
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        // TEST UNIT
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        
        bannerView.rootViewController = self
        addBannerViewToView(bannerView)
        
        let request = GADRequest()
        // TEST
        request.testDevices = ["ea221b24268abe25327e221c72a03f9f"]
        bannerView.load(request)
        
        bannerViewHeight = bannerView.frame.height
        tableBottom.constant = -bannerViewHeight
        
        
        let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
        if (!hasSeenTutorial && Items.itemLists.count == 0) {
            Items.itemLists.append(ItemList(label: "Tutorial"))
            Items.itemLists[0].items.append(Item(label: "← Set reminder time"))
            
            let item1 = Item(label: "Set recurrence period →")
            item1.reminderDate = Date(timeIntervalSinceNow: 86400)
            Items.itemLists[0].items.append(item1)
            Items.itemLists[0].items.append(Item(label: "Hold and drag to change position"))
            Items.itemLists[0].items.append(Item(label: "Swipe right to delete task"))
                
            let item2 = Item(label: "Swipe left to delete instance")
            item2.reminderDate = Date(timeIntervalSinceNow: 86400)
            item2.isRecurring = true
            item2.recurrencePeriod = 1
            item2.recurrenceUnit = 0
            Items.itemLists[0].items.append(item2)
            Items.itemLists[0].items.append(Item(label: "Pinch to set precise time"))
            UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }

        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (granted, error) in
            self.isGrantedNotificationAccess = granted
            // Define Actions
            let removeTask = UNNotificationAction(identifier: "removeTask", title: "Done!", options: [])
            let remindOneHour = UNNotificationAction(identifier: "remindOneHour", title: "1 Hour Snooze", options: [])
            
            // Define Category
            let category = UNNotificationCategory(identifier: "category", actions: [removeTask, remindOneHour], intentIdentifiers: [], options: [])
            
            // Register Category
            UNUserNotificationCenter.current().setNotificationCategories([category])
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (Items.itemLists.count > 0) {
            return Items.itemLists[selectedUnit].items.count + 1
        }
        return 0
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
            
            if (cell.contentView.gestureRecognizers?.count)! < 3 {
                let pan = UIPanGestureRecognizer(target: self, action:#selector(removeTask))
                pan.delegate = self
                cell.contentView.addGestureRecognizer(pan)
                
                let lpGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell))
                lpGestureRecognizer.minimumPressDuration = 0.5
                cell.contentView.addGestureRecognizer(lpGestureRecognizer)
                
                let swipeRightRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(showDatePicker))
                cell.contentView.addGestureRecognizer(swipeRightRecognizer)
                
                
            }

            if (item.reminderDate != nil) {
                cell.RecurringButton.isHidden = false
                
                if cell.RecurringButton.gestureRecognizers == nil {
                    let recurPan = UILongPressGestureRecognizer(target: self, action:#selector(makeRecurring))
                    recurPan.minimumPressDuration = 0.15
                    cell.RecurringButton.addGestureRecognizer(recurPan)
                }
                
                cell.RecurringButton.alpha = item.isRecurring ? 1.0 : 0.4
                cell.RecurringButton.addTarget(self, action: #selector(disableRecurrence), for: .touchUpInside)
            } else {
                cell.RecurringButton.isHidden = true
            }
            
            if cell.RemindButton.gestureRecognizers == nil {
                let remindPan = UILongPressGestureRecognizer(target: self, action:#selector(setTime))
                remindPan.minimumPressDuration = 0.15
                cell.RemindButton.addGestureRecognizer(remindPan)
            }
            
            cell.RemindButton.alpha = item.reminderDate != nil ? 1.0 : 0.4
            cell.RemindButton.addTarget(self, action: #selector(disableReminder), for: .touchUpInside)
            
            return cell
        }
    }
    
    @objc func showDatePicker(recognizer: UIPinchGestureRecognizer) {
        if (!editingTextField) {
            DatePicker.isHidden = false
            selectedCell = tableCellCheck(recognizer: recognizer)
            selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
            DatePickerConstraint.constant = -250
            tableView.scrollToRow(at: IndexPath(row: selectedCell, section: 0), at: .middle, animated: true)

            let item = Items.itemLists[selectedUnit].items[selectedCell]
            if let date = item.reminderDate {
                DatePicker.date = date
            } else {
                DatePicker.date = Date()
            }
            self.view.addGestureRecognizer(tapGesture)

            UIView.animate(withDuration: 0.2) {
                self.tableView.alpha = 0.15
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func dismissDatePicker(recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: view)
        if !DatePicker.frame.contains(point) {
            DatePicker.isHidden = true
            DatePickerConstraint.constant = 0
            self.view.removeGestureRecognizer(tapGesture)
            UIView.animate(withDuration: 0.2) {
                self.tableView.alpha = 1.0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func updateDate() {
        let item = Items.itemLists[selectedUnit].items[selectedCell]
        item.reminderDate = DatePicker.date
        tableView.reloadRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
        createPushNotification(item: item)
    }
    
    
    func turnOffRecurrence(button: UIButton, noReminder: Bool) {
        for i in 0...Items.itemLists[selectedUnit].items.count - 1 {
            let tableCell = tableView.cellForRow(at: IndexPath(item: i, section: 0))
            
            let recframe = originConverter(targetView: (button))
            let newframe = originConverter(targetView: tableCell!)
            
            if (recframe.intersects(newframe)) {
                selectedTableCell = tableCell as! TaskCell
                if let path = tableView.indexPath(for: selectedTableCell) {
                    selectedCell = path.row
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    item.recurrenceUnit = -1
                    item.recurrencePeriod = 0
                    item.isRecurring = false
                    
                    if (noReminder) {
                        item.reminderDate = nil
                    }
                    
                    tableView.reloadRows(at: [path], with: .none)
                    break
                }
            }
        }
    }
    
    @objc func disableReminder(button: UIButton) {
        turnOffRecurrence(button: button, noReminder: true)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(Items.itemLists[selectedUnit].items[selectedCell].id)])
    }
    
    @objc func disableRecurrence(button: UIButton) {
        turnOffRecurrence(button: button, noReminder: false)
    }
    
    @objc func nameNewTask(button: UIButton) {
        if (!editingTextField) {
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
    }
    
    @objc func setTime(recognizer: UIPanGestureRecognizer) {
        
        cancelOtherTouches(recognizer: recognizer)

        
        let widthIncrement = UIScreen.main.bounds.width / 6
        let heightIncrement = UIScreen.main.bounds.height / 24
        
        currX = Int(floor(recognizer.location(in: view).x / widthIncrement))
        currY = Int(floor(recognizer.location(in: view).y / heightIncrement))
        
        
        switch recognizer.state {
        case .began:
            components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
            selectedCell = tableCellCheck(recognizer: recognizer)
            selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
            
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            let dateString = formatDate(wrappedDate: item.reminderDate) ?? ""
            PanInstructions.text = "←12 hours→\n↑30 min↓\n" + dateString
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 100
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) {
                self.tableView.alpha = 0.15
            }
            PanInstructions.isHidden = false
            PanInstructions.text = "←12 hours→\n↑30 min↓\n"
        case .changed:
            components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
            components.hour = (currX * 12) + (currY / 2)
            components.minute = (currY % 2) * 30
            components.second = 0
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            item.reminderDate = gregorian.date(from: components)!
            selectedTableCell.DateField.text = formatDate(wrappedDate: item.reminderDate)
            tableView.reloadRows(at: [IndexPath(row: selectedCell, section:0)], with: .none)
            
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 150
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            let dateString = formatDate(wrappedDate: item.reminderDate) ?? ""
            PanInstructions.text = "←12 hours→\n↑30 min↓\n" + dateString
        case .ended:
            UIView.animate(withDuration: 0.2) {
                self.tableView.alpha = 1
            }
            PanInstructions.isHidden = true
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            selectedTableCell.DateField.text = formatDate(wrappedDate: item.reminderDate)
            tableView.reloadRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
            createPushNotification(item: item)
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
        
        cancelOtherTouches(recognizer: recognizer)

        
        let widthIncrement = UIScreen.main.bounds.width / 3
        let heightIncrement = UIScreen.main.bounds.height / 6
        
        currX = Int(floor(recognizer.location(in: view).x / widthIncrement))
        currY = Int(floor(recognizer.location(in: view).y / heightIncrement))
        let item = Items.itemLists[selectedUnit].items[selectedCell]
        
        switch recognizer.state {
        case .began:
            item.isRecurring = true
            setCells(recognizer: recognizer)
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 100
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            PanInstructions.isHidden = false
            PanInstructions.text = "←Period→\n↑Frequency↓\n"
            self.view.layoutIfNeeded()
        case .changed:
            item.recurrenceUnit = 2 - currX
            item.recurrencePeriod = currY + 1
            
            let halfHeight = UIScreen.main.bounds.height / 2
            if (recognizer.location(in: view).y < halfHeight) {
                PanInstructionsXPosition.constant = halfHeight - 150
            } else {
                PanInstructionsXPosition.constant = 150 - halfHeight
            }
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            let item = Items.itemLists[selectedUnit].items[selectedCell]
            if let recurString = formatRecurrence(item: item) {
                selectedTableCell.DateField.text = "\(formatDate(wrappedDate: item.reminderDate)!), \(recurString)"
                tableView.reloadRows(at: [IndexPath(row: selectedCell, section:0)], with: .none)
                PanInstructions.text = "←Period→\n↑Frequency↓\n\(recurString)"
                UIView.animate(withDuration: 0.25) {
                    self.tableView.alpha = 0.15
                }
            }
        case .ended:
            UIView.animate(withDuration: 0.25) {
                self.tableView.alpha = 1
            }
            PanInstructions.isHidden = true
            UIApplication.shared.applicationIconBadgeNumber = overdueTasks()
        default:
            break
        }
    }
    
    @objc func removeTask(recognizer: UIPanGestureRecognizer)
    {
        cancelOtherTouches(recognizer: recognizer)

        let panRightMax : CGFloat = 140.0
        let panLeftMax : CGFloat = -140.0
        switch recognizer.state {
        case .began:
            if (recognizer.view != nil) {
                view.endEditing(true)
                setCells(recognizer: recognizer)
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
                    selectedTableCell.whiteMark.image = UIImage(named: "x2")
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
                        self.createPushNotification(item: item)
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
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(item.id)])
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [String(item.id)])
                        UIApplication.shared.applicationIconBadgeNumber = self.overdueTasks()
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
        cancelOtherTouches(recognizer: recognizer)
        switch recognizer.state {
        case .began:
            view.endEditing(true)
            if recognizer.view != nil  {
            
                setCells(recognizer: recognizer)
                let textFrame = originConverter(targetView: selectedTableCell.TaskField)
                
                let label = UILabel(frame: textFrame)
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = Items.itemLists[selectedUnit].items[selectedCell].label
                var yOffset: CGFloat = 2.0
                if let fontSize = selectedTableCell.TaskField.font?.pointSize {
                    label.font = UIFont(name: "Kannada Sangam MN", size: fontSize)
                    yOffset = 19.0 - fontSize
                    if (fontSize < 17.0) {
                        yOffset -= 1
                    }
                } else {
                    label.font = UIFont(name: "Kannada Sangam MN", size: 17.0)
                }
                dragLabel = label
                view.addSubview(dragLabel!)
                view.bringSubview(toFront: dragLabel!)
                dragTopConstraint = (dragLabel?.topAnchor.constraint(equalTo: selectedTableCell.TaskField.topAnchor))!
                dragLeadingConstraint = (dragLabel?.leadingAnchor.constraint(equalTo: selectedTableCell.TaskField.leadingAnchor))!
                dragTopConstraint.constant = yOffset
                dragTopConstraint.isActive = true
                dragLeadingConstraint.isActive = true
                
                dragX = Double((dragLabel?.frame.origin.x)!)
                dragY = (dragLabel?.center.y)! - recognizer.location(in:view).y

                self.selectedTableCell.TaskField.isHidden = true
                originalOrigin = selectedTableCell.TaskField.convert(CGPoint.zero, to: view)
                originalOrigin.y += yOffset
                self.dragLabel?.center.y = recognizer.location(in: self.view).y + yOffset
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.selectedTableCell.alpha = 0.0
                }, completion: { finished in
                    self.selectedTableCell.isHidden = true
                })
                self.view.setNeedsDisplay()
            }
        case .changed:
            let point = recognizer.location(in: view)
            selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
            dragTopConstraint.isActive = false
            dragLeadingConstraint.isActive = false
                //let tView = originConverter(targetView: tableView)
            let bView = originConverter(targetView: bufferView)
                if !bView.contains(point) && point.y > 20 {
                   UIView.animate(withDuration: 0.1) {
                        self.dragLabel?.center.y = recognizer.location(in: self.view).y
                        self.dragLabel?.frame.origin.x = CGFloat(self.dragX)
                    }
                } else {
                    UIView.animate(withDuration: 0.1) {
                        self.dragLabel?.center = recognizer.location(in: self.view)
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
                           // collectionView.reloadItems(at: [IndexPath(row: oldDropCell!, section: 0)])
                            let cell = collectionView.cellForItem(at: IndexPath(row: oldDropCell!, section: 0))!
                            UIView.animate(withDuration: 0.3) {
                                cell.backgroundColor = UIColor.clear
                            }
                        }
                        //collectionView.reloadItems(at: [IndexPath(row: dropCell!, section: 0)])
                        let cell = collectionView.cellForItem(at: IndexPath(row: dropCell!, section: 0))!
                        UIView.animate(withDuration: 0.3) {
                            cell.backgroundColor = UIColor.red.withAlphaComponent(0.5)
                        }
                    }
                    break
                }
            }
            if !isIntersection && dropCell != nil {
                let oldDropCell = dropCell
                dropCell = nil
                let cell = collectionView.cellForItem(at: IndexPath(row: oldDropCell!, section: 0))!
                UIView.animate(withDuration: 0.3) {
                    cell.backgroundColor = UIColor.clear
                }
                //collectionView.reloadItems(at: [IndexPath(row: oldDropCell!, section: 0)])
            }
            
            for i in 0...Items.itemLists[selectedUnit].items.count - 1 {
                let indexPath1 = IndexPath(row: i, section: 0)
                let indexPath2 = IndexPath(row: selectedCell, section: 0)
                if let tableCell = tableView.cellForRow(at: indexPath1) {
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
                        selectedTableCell.alpha = 1.0
                        selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
                        selectedTableCell.alpha = 0.0
                        break
                    }
                }
            }
        case .ended:
            tempCell = selectedCell
            if (dragLabel == nil) { return }
            //dragTopConstraint.isActive = false
            //dragLeadingConstraint.isActive = false
            //selectedTableCell.TaskField.center.y += self.dragY
            let oldDropCell = dropCell
            dropCell = nil
            if let dCell = oldDropCell {
                //collectionView.reloadItems(at: [IndexPath(row: dCell, section: 0)])
                let cell = collectionView.cellForItem(at: IndexPath(row: dCell, section: 0))!
                UIView.animate(withDuration: 0.3) {
                    cell.backgroundColor = UIColor.clear
                }
            }
            var isIntersection = false
            for i in 0...Items.itemLists.count - 1 {
                let point = tableCollectionIntersect(it: i)
                if point != CGPoint.zero {
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    //item.modifiedDate = Date()
                    Items.itemLists[i].items.insert(item, at: 0)
                    Items.itemLists[selectedUnit].items.remove(at: selectedCell)
                    tableView.deleteRows(at: [IndexPath(row: selectedCell, section: 0)], with: .none)
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.dragLabel?.transform = (self.dragLabel?.transform.scaledBy(x: 0.01, y: 0.01))!
                        self.dragLabel?.center = point
                    }, completion: { finished in
                        self.dragLabel?.removeFromSuperview()
                        self.dragLabel = nil
                        //self.selectedTableCell.TaskField.isHidden = false
                        //self.selectedTableCell.RecurringButton.alpha = 1.0
                        //self.selectedTableCell.RemindButton.alpha = 1.0
                        //self.selectedTableCell.DateField.alpha = 1.0
                        self.selectedTableCell.isHidden = false
                        self.selectedTableCell.alpha = 1.0
                        self.selectedTableCell.TaskField.isHidden = false
                    })
                    isIntersection = true
                    break
                }
            }
            
            if (!isIntersection) {
                let item = Items.itemLists[selectedUnit].items[selectedCell]
                selectedTableCell.isHidden = false
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.dragLabel?.frame.origin = self.originalOrigin
                    //self.selectedTableCell.RecurringButton.alpha = item.isRecurring ? 1.0 : 0.4
                    //self.selectedTableCell.RemindButton.alpha = item.reminderDate != nil ? 1.0 : 0.4
                    //self.selectedTableCell.DateField.alpha = 1.0
                    self.selectedTableCell.alpha = 1.0
                }, completion: { finished in
                    self.dragLabel?.removeFromSuperview()
                    self.dragLabel = nil
                    self.selectedTableCell.TaskField.isHidden = false
                })
            }
        default:
            print("Default?")
        }
    }
    
    @objc func listOptions (recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if editingTextField {
                return
            }
            collectionViewMenuMode = true
            cancelOtherTouches(recognizer: recognizer)
            
            if let oldCell = collectionView.cellForItem(at: IndexPath(item: selectedUnit, section:0)) as? ListCell {
                oldCell.layer.borderWidth = 0
                oldCell.layer.borderColor = UIColor.clear.cgColor
            }
            
            tempUnit = collectionCellCheck(recognizer: recognizer)
            
            let cell = collectionView.cellForItem(at: IndexPath(item: tempUnit, section:0)) as! ListCell
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.blue.cgColor
            let menu = UIMenuController.shared
            
                self.becomeFirstResponder()
            
                let renameItem = UIMenuItem(title: "Rename", action: #selector(renameList))
                let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteList))
            
                menu.menuItems = [renameItem, deleteItem]
                let touchPoint = recognizer.location(in: view)
                let targetRect = CGRect(x: touchPoint.x, y: touchPoint.y, width: cell.frame.width / 2, height: cell.frame.height)
                menu.setTargetRect(targetRect, in: self.view)
                menu.setMenuVisible(true, animated: true)
            
            NotificationCenter.default.addObserver(self, selector: #selector(switchTableOnMenuHide), name: NSNotification.Name.UIMenuControllerDidHideMenu, object: nil)
            //recognizer.isEnabled = false
            //recognizer.isEnabled = true
            
        }
    }
    
    @objc func switchTableOnMenuHide() {
        collectionViewMenuMode = false
        selectedUnit = tempUnit
        
        tableView.reloadData()
    }
    @objc func renameList() {
        collectionViewMenuMode = false
        selectedUnit = tempUnit
        let cell = collectionView.cellForItem(at: IndexPath(item: selectedUnit, section:0)) as! ListCell
        cell.ListField.isEnabled = true
        cell.ListField.becomeFirstResponder()
        
        
        tableView.reloadData()
        
    }
    
    @objc func deleteList() {
        collectionViewMenuMode = false
        selectedUnit = tempUnit
        let oldCell = self.collectionView.cellForItem(at: IndexPath(row: self.selectedUnit, section: 0)) as! ListCell
        let label = oldCell.ListField.text!
        let alertController = UIAlertController(title: "Delete List \(label)?", message: nil, preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Yes", style: .destructive) {
            (action) -> Void in
            
            for item in self.Items.itemLists[self.selectedUnit].items {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            }
            self.Items.itemLists.remove(at: self.selectedUnit)
            
            self.collectionView.deleteItems(at: [IndexPath(item: self.selectedUnit, section:0)])
            if (self.selectedUnit > 0) {
                self.selectedUnit -= 1
            } else {
                self.selectedUnit = 0
            }
            self.collectionView.scrollToItem(at: IndexPath(item: self.selectedUnit, section: 0), at: .left, animated: true)
            if let cell = self.collectionView.cellForItem(at: IndexPath(row: self.selectedUnit, section: 0)) as? ListCell {
                cell.layer.borderWidth = 1.0
                cell.layer.borderColor = UIColor.blue.cgColor
            }
            self.collectionView.reloadData()
            self.tableView.reloadData()
            self.tempUnit = self.selectedUnit
        }
        let cancelAction = UIAlertAction(title: "No", style: .cancel) {
            (action) -> Void in
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // On iPads the sourceView and sourceRect must be defined for the alert to appear.
        if let popoverController = alertController.popoverPresentationController {
         popoverController.sourceView = self.view
         popoverController.sourceRect = oldCell.frame
         }
        
        present(alertController, animated: true, completion: nil)
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tempCell = indexPath.row
        if !editingTextField {
            selectedCell = indexPath.row
        }
        
        let rows = tableView.numberOfRows(inSection: 0)
        
        if (indexPath.row == rows - 1) {
            if (!editingTextField) {
                let cell = tableView.cellForRow(at: indexPath) as! AddCell
                isCreationCell = true
                if let field = cell.TaskField {
                    field.isEnabled = true
                    field.becomeFirstResponder()
                }
            }
        } else {
            if let cell = tableView.cellForRow(at: indexPath) as? TaskCell {
                if let field = cell.TaskField {
                    field.isEnabled = true
                    field.becomeFirstResponder()
                }
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
            cell.ListField.backgroundColor = UIColor.clear
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
        if !DatePicker.isHidden || collectionViewMenuMode {
            textField.resignFirstResponder()
            return
        } else {
            editingTextField = true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !editingTextField {
            textField.resignFirstResponder()
            return
        }
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
                    let item = Items.itemLists[selectedUnit].items[selectedCell]
                    item.label = text
                    if (item.reminderDate != nil) {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [String(item.id)])
                        createPushNotification(item: item)
                    }
                    
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
        //SKStoreReviewController.requestReview()
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
            
            if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) {
            
                let recframe = originConverter(targetView: (recognizer.view)!)
                let newframe = originConverter(targetView: cell)
                
                if (recframe.intersects(newframe)) {
                    return i
                }
            }
        }
        return -1
    }
    
    func tableCellCheck(recognizer: UIGestureRecognizer) -> Int {
        
        for i in 0...Items.itemLists[selectedUnit].items.count - 1 {
            let tableCell = tableView.cellForRow(at: IndexPath(item: i, section: 0))
            if let view = recognizer.view {
                let recframe = originConverter(targetView: (view))
                if let cell = tableCell {
                    let newframe = originConverter(targetView: cell)
                    if (recframe.intersects(newframe)) {
                        return i
                    }
                }
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
        if let collectionCell = collectionView.cellForItem(at: IndexPath(item: it, section: 0)) {
            let neworigin = collectionCell.convert(CGPoint.zero, to: view)
            var newframe = collectionCell.frame
            newframe.origin = neworigin
            if dragLabel != nil && dragLabel!.frame.intersects(newframe) {
                newframe.origin.x += newframe.width / 2
                newframe.origin.y += newframe.height / 2
                return newframe.origin
            } else {
                return CGPoint.zero
            }
        } else {
            return CGPoint.zero
        }
    }
    
    func formatDate(wrappedDate: Date?) -> String? {
        //Yesterday, today, tomorrow
        if let date = wrappedDate {
            let gregorian = Calendar(identifier: .gregorian)
            let dateComponents = gregorian.dateComponents([.year, .month, .day], from: date)
            let todayComponents = gregorian.dateComponents([.year, .month, .day], from: Date())
            let day = dateComponents.day!
            let today = todayComponents.day!
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            
            if (dateComponents.month! != todayComponents.month! || dateComponents.year! != todayComponents.year!) {
                dateFormatter.dateStyle = .short
                return dateFormatter.string(from: date)
            }

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
        UIApplication.shared.applicationIconBadgeNumber = overdueTasks()
        completionHandler([.alert, .badge, .sound])
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setCells(recognizer: UIGestureRecognizer) {
        selectedCell = tableCellCheck(recognizer: recognizer)
        selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0)) as! TaskCell
    }
    func createPushNotification(item: Item) {
        if isGrantedNotificationAccess{
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id])
            UIApplication.shared.applicationIconBadgeNumber = overdueTasks()
            if let date = item.reminderDate {
                let seconds = date.timeIntervalSince(Date())
                if (seconds > 0) {
                    //add notification code here
                    let content = UNMutableNotificationContent()
                    content.body = item.label
                    content.categoryIdentifier = "category"
                    content.sound = UNNotificationSound(named: "silence")

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                    let request = UNNotificationRequest(identifier: String(item.id), content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    UIApplication.shared.applicationIconBadgeNumber = overdueTasks()
                    UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
                        for request in requests {
                            print("Request \(request.trigger!) for id \(request.identifier)")
                        }
                    })
                }
            } else {
                return
            }
        }
    }
    
    func overdueTasks() -> Int {
        var overdueTasks : Int = 0
        for list in Items.itemLists {
            for item in list.items {
                let date = Date()
                if item.reminderDate != nil && item.reminderDate! < date {
                    overdueTasks += 1
                }
            }
        }
        return overdueTasks
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            return
        }
        for list in Items.itemLists {
            for i in 0...list.items.count - 1 {
                let item = list.items[i]
                if item.id == response.notification.request.identifier {
                    switch response.actionIdentifier {
                    case "removeTask":
                        if (item.isRecurring) {
                            var unit: Calendar.Component
                            if item.recurrenceUnit == 0 {
                                unit = .day
                            } else if item.recurrenceUnit == 1 {
                                unit = .weekOfYear
                            } else {
                                unit = .month
                            }
                            item.reminderDate = Calendar.current.date(byAdding: unit, value: item.recurrencePeriod, to: item.reminderDate!)
                            self.createPushNotification(item: item)
                            return
                        } else {
                            self.Items.itemLists[self.selectedUnit].items.remove(at: i)
                            UIApplication.shared.applicationIconBadgeNumber = self.overdueTasks()
                            return
                        }
                    case "remindOneHour":
                        if let date = item.reminderDate {
                            item.reminderDate = date.addingTimeInterval(3600)
                            createPushNotification(item: item)
                            return
                        }
                    default:
                        print("Error")
                    }
                }
            }
        }
        completionHandler()
    }

    
    @objc func keyboardWillShow(notification: NSNotification) {
         if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableBottom.constant = -keyboardSize.height - bannerViewHeight
                self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableBottom.constant = -bannerViewHeight
            self.view.layoutIfNeeded()
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView, attribute: .bottom, relatedBy: .equal,toItem: bottomLayoutGuide,attribute: .top, multiplier: 1, constant: 0),
             NSLayoutConstraint(item: bannerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX,multiplier: 1, constant: 0)
            ])
    }
    
    func cancelOtherTouches(recognizer: UIGestureRecognizer) {
        if !DatePicker.isHidden {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }
    }
}
