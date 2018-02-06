//
//  AppDelegate.swift
//  Timely Goals
//
//  Created by David Solomon on 1/3/18.
//  Copyright © 2018 David Solomon. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let itemStore = ItemStore()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let viewController = window!.rootViewController as! ViewController
        viewController.Items = itemStore
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let success = itemStore.saveChanges()
        if (success) {
            print("Saved all of the Items")
        }
        else {
            print("Could not save any of the Items")
        }
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let viewController = window!.rootViewController as! ViewController
        
        if (viewController.tableView == nil) {
            return
        }
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Specify date components
        /*var dateComponents = DateComponents()
        dateComponents.year = 2018
        dateComponents.month = 1
        dateComponents.day = 11
        dateComponents.timeZone = TimeZone(abbreviation: "EST")
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        let currentDate = userCalendar.date(from: dateComponents)!*/
        
        
       /* for i in 0...viewController.Items.items.count - 1 {
            if viewController.Items.items[i].count == 0 {
                continue
            }
            var j = 0
            while j < viewController.Items.items[i].count {
                let date1 = calendar.startOfDay(for: viewController.Items.items[i][j].modifiedDate)
                let date2 = calendar.startOfDay(for: currentDate)
                var newPeriod : Bool = false
                switch i {
                case 0, 5:
                    let difference = calendar.dateComponents([.day], from: date1, to: date2)
                    if (difference.day! > 0) {
                        newPeriod = true
                    }
                case 1, 6:
                    let difference = calendar.dateComponents([.weekdayOrdinal], from: date1, to: date2)
                    if (difference.weekdayOrdinal! > 0) {
                        newPeriod = true
                    }
                case 2, 7:
                    let difference = calendar.dateComponents([.month], from: date1, to: date2)
                    if (difference.month! > 0) {
                        newPeriod = true
                    }
                case 3, 8:
                    let difference = calendar.dateComponents([.year], from: date1, to: date2)
                    if (difference.year! > 0) {
                        newPeriod = true
                    }
                case 4:
                    break
                default:
                    print("Something seriously went wrong in the app delegate")
                }
                if newPeriod {
                    if viewController.Items.items[i][j].isRecurring() {
                        viewController.Items.items[i][j].isDoneForNow = false
                        viewController.Items.items[i][j].modifiedDate = Date()
                        if (i > 4) {
                            let item = viewController.Items.items[i][j]
                            viewController.Items.items[i - 5].insert(item, at: item.oldPosition)
                            viewController.Items.items[i].remove(at: j)
                            j -= 1
                        }
                    } else {
                        let item = viewController.Items.items[i][j]
                        viewController.Items.items[i].remove(at: j)
                        j -= 1
                        viewController.Items.items[4].append(item)
                    }
                }
                j += 1
            }
            viewController.tableView.reloadData()
        }*/
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Timely_Goals")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

