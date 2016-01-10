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
    var bookmarks = NSMutableArray()
    var timer = NSTimer()

    func setup() {
        parser = RSSParser()
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "updateData", userInfo: nil, repeats: true)
   }
    
    func perform() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.parser.parse(completionHandler: { items in
                if self.mergeBookmarks(items) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    func mergeBookmarks(items: NSArray) -> Bool {
        var shouldReload = false
        for item in items.reverse() {
            let url = item["bookmarkURL"] as! NSString
            let predicate = NSPredicate(format: "bookmarkURL == %@", url)
            let results = bookmarks.filteredArrayUsingPredicate(predicate)
            if results.count > 0 {
                let b: NSMutableDictionary = results[0] as! NSMutableDictionary
                if let count = item["count"]! {
                    if count as! String != b["count"] as! String {
                        b["count"] = count as! String
                        shouldReload = true
                    }
                }
                if let comment = item["comment"]! {
                    if comment as! String != b["comment"] as! String {
                        b["comment"] = comment as! String
                        shouldReload = true
                    }
                }
            } else {
                bookmarks.insertObject(item, atIndex: 0)
                shouldReload = true
                let notification = NSUserNotification()
                if let creator = item["creator"]!, let title = item["title"]! {
                    notification.title = "\(creator) \(title)"
                }
                if let comment = item["comment"]! {
                    notification.subtitle = "\(comment)"
                }
                if let count = item["count"]! {
                    notification.informativeText = "\(count) users"
                }
//                notification.contentImage = NSImage(named: "hoge")
                notification.userInfo = ["hoge": "title"]
                notification.soundName = NSUserNotificationDefaultSoundName
                NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                print(notification)
            }
        }
        return shouldReload
    }
    
    @IBAction func reload(sender: AnyObject) {
        perform()
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
    
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        let info = notification.userInfo as! [String:String]
        
//        print(info["title"]!)
    }
}
