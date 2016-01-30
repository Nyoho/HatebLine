//
//  TimelineViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Alamofire

class TimelineViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSUserNotificationCenterDelegate {

    var parser: RSSParser!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var bookmarkArrayController: NSArrayController!
    var bookmarks = NSMutableArray()
    var timer = NSTimer()

    lazy var managedObjectContext: NSManagedObjectContext = {
        return (NSApplication.sharedApplication().delegate
            as? AppDelegate)?.managedObjectContext }()!    
    
    var sortDescriptors:[NSSortDescriptor] = [NSSortDescriptor(key: "date", ascending: false)]
    
    func setup() {
        parser = RSSParser()
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        timer = NSTimer(timeInterval: 60, target: self, selector: "updateData", userInfo: nil, repeats: true)
        let runLoop = NSRunLoop.currentRunLoop()
        runLoop.addTimer(timer, forMode: NSRunLoopCommonModes)
        //tableView.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
    }
    
    func perform() {
        guard let hatenaID = NSUserDefaults.standardUserDefaults().valueForKey("hatenaID") as! String? else {
            // ID を入れるように促す
            return
        }
        parser.userName = hatenaID
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.parser.parse(completionHandler: { items in
                if self.mergeBookmarks(items) {
                    dispatch_async(dispatch_get_main_queue()) {
                        //self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    func mergeBookmarks(items: NSArray) -> Bool {
        let moc = self.managedObjectContext
        var shouldReload = false
        for item in items.reverse() {
            let bookmarkUrl = item["bookmarkUrl"] as! NSString
            let request = NSFetchRequest(entityName: "Bookmark")
            request.predicate = NSPredicate(format: "bookmarkUrl == %@", bookmarkUrl)
            do {
                let fetchedBookmarks = try moc.executeFetchRequest(request) as! [Bookmark]
                if (fetchedBookmarks.count > 0) {
                    let b = fetchedBookmarks.first! as Bookmark
                    if let count = Int(item["count"]! as! String) {
                        if count != b.page?.count {
                            b.page?.count = count
                            shouldReload = true
                        }
                    }
                    if let comment = item["comment"]! {
                        if comment as! String != b.comment {
                            if comment as! String != "" {
                                b.comment = comment as! String
                                shouldReload = true
                            }
                        }
                    }
                } else {
                    let bmEntity = NSEntityDescription.entityForName("Bookmark", inManagedObjectContext: moc)
                    let bookmark = NSManagedObject(entity: bmEntity!, insertIntoManagedObjectContext: moc) as! Bookmark
                    var user: NSManagedObject?
                    var page: NSManagedObject?
                    
                    let usersFetch = NSFetchRequest(entityName: "User")
                    if let creator = item["creator"]! {
                        usersFetch.predicate = NSPredicate(format: "name == %@", creator as! String)
                        do {
                            let fetchedUsers = try moc.executeFetchRequest(usersFetch) as! [User]
                            if (fetchedUsers.count > 0) {
                                user = fetchedUsers.first!
                            } else {
                                let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: moc)
                                user = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: moc)
                                user?.setValue(creator as! String, forKey: "name")
                            }
                        } catch {
                            fatalError("Failed to fetch users: \(error)")
                        }
                    }
                    let pagesFetch = NSFetchRequest(entityName: "Page")
                    if let url = item["link"]! {
                        pagesFetch.predicate = NSPredicate(format: "url == %@", url as! String)
                        do {
                            let fetchedPages = try moc.executeFetchRequest(pagesFetch) as! [Page]
                            if (fetchedPages.count > 0) {
                                page = fetchedPages.first!
                            } else {
                                let entity = NSEntityDescription.entityForName("Page", inManagedObjectContext: moc)
                                page = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: moc)
                                page?.setValue(url as! String, forKey: "url")
                                if let b = item["title"]! { page?.setValue(b, forKey: "title") }
                                if let b = item["count"]! {
                                    page?.setValue(Int(b as! String), forKey: "count")
                                }
                                if let b = item["content"]! {
                                    if b as! String != "" {
                                        page?.setValue(b, forKey: "content")
                                    }
                                }
                            }
                        } catch {
                            fatalError("Failed to fetch pages: \(error)")
                        }
                    }
                    
                    bookmark.setValue(user, forKey: "user")
                    bookmark.setValue(page, forKey: "page")
                    if let b = item["bookmarkUrl"]! {
                        bookmark.setValue(b, forKey: "bookmarkUrl")
                    }
                    if let b = item["date"]! {
                        let dateFormatter = NSDateFormatter()
                        let locale = NSLocale(localeIdentifier: "en_US_POSIX")
                        dateFormatter.locale = locale
                        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
                        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                        let date = dateFormatter.dateFromString(b as! String)
                        bookmark.setValue(date, forKey: "date")
                    }
                    if let b = item["comment"]! {
                        if b as! String != "" {
                            bookmark.setValue(b, forKey: "comment")
                        }
                    }
                    //                if let creator = item["creator"]! {
                    //                    bookmarkObject.setValue(creator, forKey: "user")
                    //                }
                    
                    //                bookmarks.insertObject(item, atIndex: 0)
                    shouldReload = true
                    let notification = NSUserNotification()
                    if let creator = item["creator"]! {
                        notification.title = "\(creator) がブックマークを追加しました"
                    }
                    if let comment = item["comment"]!, let title = item["title"]!, let count = item["count"]! {
                        let separator: String = comment as! String == "" ? "" : " / "
                        notification.informativeText = "(\(count)) \(comment)\(separator)\(title)"
                    }
                    //                notification.contentImage = NSImage(named: "hoge")
                    notification.userInfo = ["hoge": "title"]
                    NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                }
            } catch {
                fatalError("Failed to fetch bookmarks: \(error)")
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), {
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
        })
        return shouldReload
    }
    
    @IBAction func reload(sender: AnyObject) {
        perform()
    }
    
    @IBAction func openInBrowser(sender: AnyObject) {
        let array = bookmarkArrayController.selectedObjects as! [Bookmark]
        if array.count > 0 {
            if let bookmark = array.first, let urlString = bookmark.page?.url, let url = NSURL(string: urlString) {
                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
    }

    func refresh() {
        tableView.reloadData()
    }

    func updateData() {
        reload(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setup()
        perform()
    }
    
/*
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
   */
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var heightOfRow: CGFloat = 96
        let bookmark = self.bookmarkArrayController.arrangedObjects[row] as! Bookmark
        if let cell = tableView.makeViewWithIdentifier("Bookmark", owner: self) as! BookmarkCellView? {
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
            let size = NSMakeSize(tableView.tableColumns[0].width, 43.0);
            if let username = bookmark.user?.name {
                cell.textField?.stringValue = username
            }
            if let comment = bookmark.comment {
                cell.commentTextField?.stringValue = comment
                cell.commentTextField?.preferredMaxLayoutWidth = size.width - (5+8+3+48)
            }
            if let title = bookmark.page?.title {
                cell.titleTextField?.stringValue = title
                // FIXME: temporarily, minus titleTextField's paddings
                cell.titleTextField?.preferredMaxLayoutWidth = size.width - (5+8+3+48+16)
            }
            // cell.countTextField?.stringValue = "\(bookmark.count) users"
            cell.needsLayout = true
            cell.layoutSubtreeIfNeeded()
            NSAnimationContext.beginGrouping()
            NSAnimationContext.currentContext().duration = 0.0
            heightOfRow = cell.fittingSize.height
            NSAnimationContext.endGrouping()
        }
        
        return heightOfRow < 48 ? 48 : heightOfRow
    }

    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        let info = notification.userInfo as! [String:String]
        
//        print(info["title"]!)
    }
}