//
//  AppDelegate.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/3.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Alamofire
import AlamofireImage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var window: NSWindow!

    var parser: RSSParser!
    @IBOutlet weak var tableView: NSTableView!
    var bookmarks = NSArray()
    
    func setup() {
        parser = RSSParser()
    }
    
    func perform() {
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.parser.parse(completionHandler: { items in
                self.bookmarks = items
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        setup()
        perform()
        tableView.reloadData()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "jp.nyoho.HatebLine" in the user's Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.URLByAppendingPathComponent("jp.nyoho.HatebLine")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("HatebLine", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = NSFileManager.defaultManager()
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
            if !properties[NSURLIsDirectoryKey]!.boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CocoaAppCD.storedata")
            do {
                try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
            } catch {
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.sharedApplication().presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.sharedApplication().presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
            return .TerminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .TerminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .TerminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButtonWithTitle(quitButton)
            alert.addButtonWithTitle(cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertFirstButtonReturn {
                return .TerminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .TerminateNow
    }

    // MARK: - TableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return bookmarks.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == "Bookmark" {
            if let cell = tableView.makeViewWithIdentifier("Bookmark", owner: self) as! BookmarkCellView? {
            let bookmark = bookmarks[row] as! NSMutableDictionary
                let username = bookmark["creator"] as! String
                cell.textField?.stringValue = username
                var com = bookmark["comment"] as! String
                if com != "" { com += "\n" }
                cell.titleTextField?.stringValue = "\(com)\(bookmark["title"] as! String)"
                cell.countTextField?.stringValue = "\(bookmark["count"] as! String) users"
                
                let dateFormatter = NSDateFormatter()
                let locale = NSLocale(localeIdentifier: "en_US_POSIX")
                dateFormatter.locale = locale
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
                dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
//                let date = dateFormatter.dateFromString(bookmark["date"] as! String)
                
                cell.dateTextField?.stringValue = bookmark["date"] as! String
                
                let twoLetters = (username as NSString).substringToIndex(2)
                Alamofire.request(.GET, "http://cdn1.www.st-hatena.com/users/\(twoLetters)/\(username)/profile.gif")
                    .responseImage { response in
                        if let image = response.result.value {
                            cell.imageView?.wantsLayer = true
                            cell.imageView?.layer?.cornerRadius = 5.0
                            cell.imageView?.image = image
                        }
                }
                return cell
            }
        }
        return nil
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var heightOfRow: CGFloat = 48
        let bookmark = bookmarks[row] as! NSMutableDictionary
        if let cell = tableView.makeViewWithIdentifier("Bookmark", owner: self) as! BookmarkCellView? {
            let username = bookmark["creator"] as! String
            cell.textField?.stringValue = username
            var com = bookmark["comment"] as! String
            if com != "" { com += "\n" }
            cell.titleTextField?.stringValue = "\(com)\(bookmark["title"] as! String)"
            cell.countTextField?.stringValue = "\(bookmark["count"] as! String) users"
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
            let size = NSMakeSize(tableView.tableColumns[0].width, 43.0);
            // FIXME: temporarily, minus titleTextField's paddings
            cell.titleTextField.preferredMaxLayoutWidth = size.width - (5+8+3+48)
            cell.needsLayout = true
            cell.layoutSubtreeIfNeeded()
            NSAnimationContext.beginGrouping()
            NSAnimationContext.currentContext().duration = 0.0
            heightOfRow = cell.fittingSize.height
            NSAnimationContext.endGrouping()
        }
        return heightOfRow < 48 ? 48 : heightOfRow
    }
    
    // MARK: - NSWindowDelegate
    func windowDidResize(notification: NSNotification) {
            tableView.reloadData()
    }
}

