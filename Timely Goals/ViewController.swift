//
//  ViewController.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    var Items: [[Item]] = [[],[],[],[]]
    var TimeUnits = ["Daily", "Weekly", "Monthly", "Yearly"]
    
    var selectedUnit = 0
    var selectedCell = 0
    var tempUnit = 0
    private var dragLabel: UILabel?
    
    var oldPoint = CGPoint()
    var oldHeight : CGFloat = 0.0
    var oldWidth : CGFloat = 0.0
    
    var previousIndexPath = IndexPath(item: 0, section: 0)
    var editingTextField : Bool = false
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.selectItem(at: previousIndexPath, animated: false, scrollPosition: .left)
        collectionView.reloadItems(at: [previousIndexPath])
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
        
        let lpGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell))
        
        // Method of identifying cells
        cell.contentView.addGestureRecognizer(lpGestureRecognizer)
        return cell
    }
    
    @objc func didLongPressCell (recognizer: UILongPressGestureRecognizer) {
       
        
        switch recognizer.state {
        case .began:
            if recognizer.view != nil  {
                
                for i in 0...Items[selectedUnit].count - 1 {
                    let tableCell = tableView.cellForRow(at: IndexPath(item: i, section: 0))
                    let neworigin = tableCell?.convert(CGPoint.zero, to: view)
                    var newframe = tableCell?.frame
                    newframe?.origin = neworigin!
                    
                    var recframe = recognizer.view?.frame
                    let recorigin = recognizer.view?.convert(CGPoint.zero, to: view)
                    recframe?.origin = recorigin!
                    
                    if (recframe?.intersects(newframe!))! {
                        selectedCell = i
                    }
                }
                
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = Items[selectedUnit][selectedCell].label
                dragLabel = label
                
                view.addSubview(dragLabel!)
                view.bringSubview(toFront: dragLabel!)
                dragLabel?.center = recognizer.location(in: view)
                
                let selectedTableCell = tableView.cellForRow(at: IndexPath(item: selectedCell, section: 0))
                selectedTableCell?.isHidden = true
                
                view.setNeedsDisplay()
                print("Begin")
            }
        case .changed:
            dragLabel?.center = recognizer.location(in: view)
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            self.Items[selectedUnit].remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
 
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let fromIndex = sourceIndexPath.row
        let toIndex = destinationIndexPath.row
        
            if fromIndex == toIndex {
                return
            }
            
            let movedItem = Items[fromIndex]
            Items.remove(at: fromIndex)
            Items.insert(movedItem, at: toIndex)
        
    }
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.row == Items.count - 1 ||
            proposedDestinationIndexPath.row == Items.count - 1 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
    
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        tempUnit = indexPath.row
        if !editingTextField {
            selectedUnit = indexPath.row
        }
        
        let oldcell = collectionView.cellForItem(at: previousIndexPath)
        let cell = collectionView.cellForItem(at: indexPath)
        
        oldcell?.layer.borderWidth = 0.0
        oldcell?.layer.borderColor = UIColor.clear.cgColor
        
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
    
}

