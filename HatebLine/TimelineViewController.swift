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
            performSegueWithIdentifier("ShowAccountSetting", sender: self)
            return
        }
        parser.userName = hatenaID
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            self.parser.parse(completionHandler: { items in
                self.mergeBookmarks(items)
            })
        })
    }
    
    func mergeBookmarks(items: NSArray) {
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.parentContext = managedObjectContext
        moc.performBlock {
            var newBookmarks = [Bookmark]()
            for item in items.reverse() {
                let bookmarkUrl = item["bookmarkUrl"] as! NSString
                let request = NSFetchRequest(entityName: "Bookmark")
                request.predicate = NSPredicate(format: "bookmarkUrl == %@", bookmarkUrl)
                do {
                    let fetchedBookmarks = try moc.executeFetchRequest(request) as! [Bookmark]
                    if (fetchedBookmarks.count > 0) { // exists, so update
                        let b = fetchedBookmarks.first! as Bookmark
                        if let count = Int(item["count"]! as! String) {
                            if count != b.page?.count {
                                b.page?.count = count
                            }
                        }
                        if let comment = item["comment"] as? String {
                            if comment != b.comment {
                                b.comment = comment
                            }
                        }
                        let tags = NSMutableSet()
                        for tagString in item["tags"] as! [String] {
                            let tag = Tag.name(tagString, inManagedObjectContext: moc)
                            tags.addObject(tag)
                        }
                        b.setValue(tags, forKey: "tags")
                    } else { // does not exsist, so create
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
                        let tags = NSMutableSet()
                        for tagString in item["tags"] as! [String] {
                            let tag = Tag.name(tagString, inManagedObjectContext: moc)
                            tags.addObject(tag)
                        }
                        bookmark.setValue(tags, forKey: "tags")
                        
                        newBookmarks.append(bookmark)
                    }
                } catch {
                    fatalError("Failed to fetch bookmarks: \(error)")
                }
                
            }
            if moc.hasChanges {
                do {
                    try moc.save()
                    for bookmark: Bookmark in newBookmarks {
                        let notification = NSUserNotification()
                        if let creator = bookmark.user?.name {
                            notification.title = "\(creator) がブックマークを追加しました"
                        }
                        var commentString = ""
                        if let comment = bookmark.comment {
                            commentString = comment
                        }
                        if let title = bookmark.page?.title, let count = bookmark.page?.count {
                            let separator = commentString == "" ? "" : " / "
                            notification.informativeText = "(\(count)) \(commentString)\(separator)\(title)"
                        }
                        //                notification.contentImage = NSImage(named: "hoge")
                        if let url = bookmark.bookmarkUrl {
                            notification.userInfo = ["bookmarkUrl": url]
                        }
                        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                    }
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
            self.managedObjectContext.performBlock {
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Failure to save main context: \(error)")
                }
            }
        }
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

    @IBAction override func quickLookPreviewItems(sender: AnyObject?) {
        let indexes = tableView.selectedRowIndexes
        if (indexes.count > 0) {
            performSegueWithIdentifier("QuickLook", sender: self)
        }
    }

    @IBAction func openBookmarkPageInBrowser(sender: AnyObject) {
        let array = bookmarkArrayController.selectedObjects as! [Bookmark]
        if array.count > 0 {
            if let bookmark = array.first, let urlString = bookmark.page?.url, let url = NSURL(string: "http://b.hatena.ne.jp/entry/\(urlString)") {
                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
    }

    @IBAction func openUserPageInBrowser(sender: AnyObject) {
        let array = bookmarkArrayController.selectedObjects as! [Bookmark]
        if array.count > 0 {
            if let bookmark = array.first, let name = bookmark.user?.name, let url = NSURL(string: "http://b.hatena.ne.jp/\(name)/") {
                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
    }

    @IBAction func updateSearchString(sender: AnyObject) {
        if sender.isKindOfClass(NSSearchField) {
            let field = sender as! NSSearchField
            let s = field.stringValue
            bookmarkArrayController.filterPredicate = { () -> NSPredicate? in
                if s == "" {
                    return nil
                } else {
                    return NSPredicate(format: "(page.title contains[c] %@) OR (comment contains[c] %@) OR (user.name contains[c] %@)", s, s, s)
                }
            }()
        }
    }
    
    @IBAction func showComments(sender: AnyObject) {
        let indexes = tableView.selectedRowIndexes
        if (indexes.count > 0) {
            performSegueWithIdentifier("ShowComments", sender: self)
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "QuickLook":
                if segue.isKindOfClass(TablePopoverSegue) {
                    let popoverSegue = segue as! TablePopoverSegue
                    popoverSegue.preferredEdge = NSRectEdge.MaxX
                    popoverSegue.popoverBehavior = .Transient
                    popoverSegue.anchorTableView = tableView
                let indexes = tableView.selectedRowIndexes
                if (indexes.count > 0) {
                    if let bookmark = bookmarkArrayController.arrangedObjects[indexes.firstIndex] as? Bookmark {
                        let vc = segue.destinationController as? QuickLookWebViewController
                        vc?.representedObject = bookmark.page?.url
                    }
                }
                }
            case "ShowComments":
                if segue.isKindOfClass(TablePopoverSegue) {
                    let popoverSegue = segue as! TablePopoverSegue
                    popoverSegue.preferredEdge = NSRectEdge.MaxX
                    popoverSegue.popoverBehavior = .Transient
                    popoverSegue.anchorTableView = tableView
                    let indexes = tableView.selectedRowIndexes
                    if (indexes.count > 0) {
                        if let bookmark = bookmarkArrayController.arrangedObjects[indexes.firstIndex] as? Bookmark {
                            let vc = segue.destinationController as? CommentsViewController
                            vc?.representedObject = bookmark.page?.url
                        }
                    }
                }
            case "ShowAccountSetting":
                break
            default:
                break
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
        var heightOfRow: CGFloat = 48
        let bookmark = self.bookmarkArrayController.arrangedObjects[row] as! Bookmark
        if let cell = tableView.makeViewWithIdentifier("Bookmark", owner: self) as! BookmarkCellView? {
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
            let size = NSMakeSize(tableView.tableColumns[0].width, 43.0);
//            if let username = bookmark.user?.name {
//                cell.textField?.stringValue = username
//            }
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
//            cell.needsLayout = true
//            cell.layoutSubtreeIfNeeded()
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.currentContext().duration = 0.0
            heightOfRow = cell.fittingSize.height
//            NSAnimationContext.endGrouping()
        }
        return heightOfRow < 48 ? 48 : heightOfRow
    }

    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        if let c = cell as? NSTableRowView {
        if (tableView.selectedRowIndexes.containsIndex(row)) {
            c.backgroundColor = NSColor.yellowColor()
        } else {
            c.backgroundColor = NSColor.whiteColor()
        }
//        c.drawsBackground = true
        }
    }

    func tableView(tableView: NSTableView, shouldTypeSelectForEvent event: NSEvent, withCurrentSearchString searchString: String?) -> Bool {
        print(event.keyCode)
        return true
    }
    

    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if let info = notification.userInfo as? [String:String] {
            if let bookmarkUrl = info["bookmarkUrl"] {
                let moc = managedObjectContext
                do {
                    let request = NSFetchRequest(entityName: "Bookmark")
                    request.predicate = NSPredicate(format: "bookmarkUrl == %@", bookmarkUrl)
                    let results = try moc.executeFetchRequest(request) as! [Bookmark]
                    if (results.count > 0) {
                        bookmarkArrayController.setSelectedObjects(results)
                        NSAnimationContext.runAnimationGroup({ context in
                            self.tableView.animator().scrollRowToVisible(self.tableView.selectedRow)
                            }, completionHandler: nil)
                    }
                } catch {
                    fatalError("Failure: \(error)")
                }
            }

        }
    }

}
