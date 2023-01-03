//
//  TimelineViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Alamofire
import Cocoa
import Question

class TimelineViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSUserNotificationCenterDelegate {
    var parser: RSSParser!
    var parserOfMyFeed: RSSParser!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var bookmarkArrayController: NSArrayController!
    var bookmarks = NSMutableArray()
    var timer = Timer()

    @objc lazy var persistentContainer = {
        (NSApplication.shared.delegate
           as! AppDelegate).persistentContainer
    }()

    @objc dynamic var managedObjectContext = (NSApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    @objc var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "date", ascending: false)]

    func favoriteUrl() -> URL? {
        guard let hatenaID = UserDefaults.standard.value(forKey: "hatenaID") as? String else {
            performSegueShowAccountSetting()
            return nil
        }
        guard let feedToken = UserDefaults.standard.value(forKey: "feedToken") as? String else {
            performSegueShowAccountSetting()
            return nil
        }
        guard let url = URL(string: "https://b.hatena.ne.jp/\(hatenaID)/favorite.rss?key=\(feedToken)") else { return nil }
        // NSURL(string: "file:///tmp/favorite.rss")
        return url
    }

    func myFeedUrl() -> URL? {
        guard let hatenaID = UserDefaults.standard.value(forKey: "hatenaID") as? String else {
            performSegueShowAccountSetting()
            return nil
        }
        guard let url = URL(string: "https://b.hatena.ne.jp/\(hatenaID)/rss") else { return nil }
        return url
    }

    func setup() {
        QuestionBookmarkManager.shared.setConsumerKey(consumerKey: Config.consumerKey, consumerSecret: Config.consumerSecret)
        guard let url = favoriteUrl() else { return }
        parser = RSSParser(url: url)
        guard let myUrl = myFeedUrl() else { return }
        parserOfMyFeed = RSSParser(url: myUrl)
        NSUserNotificationCenter.default.delegate = self
        timer = Timer(timeInterval: 60, target: self, selector: #selector(TimelineViewController.updateData), userInfo: nil, repeats: true)
        let runLoop = RunLoop.current
        runLoop.add(timer, forMode: RunLoop.Mode.common)
    }

    func perform() {
        guard let url = favoriteUrl() else { return }
        parser.feedUrl = url
        deleteOldBookmarks()
        DispatchQueue.global().async {
            self.parser.parse(completionHandler: { items in
                self.mergeBookmarks(items)

                guard let url = self.myFeedUrl() else { return }
                self.parserOfMyFeed.feedUrl = url
                DispatchQueue.global().async {
                    self.parserOfMyFeed.parse(completionHandler: { items in
                        self.mergeBookmarks(items)
                    })
                }

            })
        }
    }

    func deleteOldBookmarks() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
        let date = NSDate(timeIntervalSinceNow: -3600 * 24 * 100)
        fetchRequest.predicate = NSPredicate(format: "date <= %@", date)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.execute(deleteRequest)
        } catch let error as NSError {
            // handle error here
            NSLog("\(error)")
        }
    }

    func mergeBookmarks(_ items: [[String: Any]]) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = managedObjectContext
        moc.parent?.mergePolicy = NSOverwriteMergePolicy
        moc.perform {
            var newBookmarks = [Bookmark]()
            for item in items.reversed() {
                if let bookmark = self.newBookmark(moc: moc, item: item) {
                    newBookmarks.append(bookmark)
                }
            }
            if moc.hasChanges {
                do {
                    try moc.save()
                    self.managedObjectContext.performAndWait {
                        if let enabled = UserDefaults.standard.value(forKey: "enableNotification") as? Bool, enabled {
                            self.notifyNewObjects(newBookmarks)
                        }
                    }
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
            self.managedObjectContext.perform {
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Failure to save main context: \(error)")
                }
            }
        }
    }

    func updateBookmark(moc: NSManagedObjectContext, fetchedBookmarks: [Bookmark], item: [String: Any]) {
        let b = fetchedBookmarks.first! as Bookmark
        if let count = item["count"] as? String, let bcount = b.page?.count {
            if let n = Int(count), n != Int(truncating: bcount) {
                b.page?.count = NSNumber(value: n)
            }
        }
        if let title = item["title"] as? String, let btitle = b.page?.title {
            if title != btitle {
                b.page?.title = title
            }
        }
        if let comment = item["comment"] as? String {
            if comment != b.comment {
                b.comment = comment
            }
        }
        let tags = NSMutableSet()
        guard let tagsArray = item["tags"] as? [String] else { return }
        for tagString in tagsArray {
            let tag = Tag.name(tagString, inManagedObjectContext: moc)
            tags.add(tag)
        }
        b.setValue(tags, forKey: "tags")
    }

    func createBookmark(moc: NSManagedObjectContext, item: [String: Any]) -> Bookmark {
        let bmEntity = NSEntityDescription.entity(forEntityName: "Bookmark", in: moc)
        guard let bookmark = NSManagedObject(entity: bmEntity!, insertInto: moc) as? Bookmark else {
            preconditionFailure("bookmark must be Bookmark")
        }
        var user: NSManagedObject?
        var page: NSManagedObject?

        let usersFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        if let creator = item["creator"] as? String {
            usersFetch.predicate = NSPredicate(format: "name == %@", creator)
            do {
                guard let fetchedUsers = try moc.fetch(usersFetch) as? [User] else {
                    preconditionFailure("fetched object must be [User]")
                }
                if fetchedUsers.count > 0 {
                    user = fetchedUsers.first!
                } else {
                    let entity = NSEntityDescription.entity(forEntityName: "User", in: moc)
                    user = NSManagedObject(entity: entity!, insertInto: moc)
                    user?.setValue(creator, forKey: "name")
                }
            } catch {
                fatalError("Failed to fetch users: \(error)")
            }
        }
        let pagesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Page")
        if let url = item["link"] as? String {
            pagesFetch.predicate = NSPredicate(format: "url == %@", url)
            do {
                guard let fetchedPages = try moc.fetch(pagesFetch) as? [Page] else {
                    preconditionFailure("fetched object must be [Page]")
                }
                if fetchedPages.count > 0 {
                    page = fetchedPages.first!
                } else {
                    let entity = NSEntityDescription.entity(forEntityName: "Page", in: moc)
                    page = NSManagedObject(entity: entity!, insertInto: moc)
                    page?.setValue(url, forKey: "url")
                    if let b = item["title"] as? String { page?.setValue(b, forKey: "title") }
                    if let b = item["count"] as? String {
                        if let n = Int(b) { page?.setValue(n, forKey: "count") }
                    }
                    if let b = item["content"] as? String {
                        if b != "" {
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
        if let b = item["bookmarkUrl"] as? String {
            bookmark.setValue(b, forKey: "bookmarkUrl")
        }
        if let b = item["date"] as? String {
            let dateFormatter = DateFormatter()
            let locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = locale
            dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            let date = dateFormatter.date(from: b)
            bookmark.setValue(date, forKey: "date")
        }
        if let b = item["comment"] as? String {
            if b != "" {
                bookmark.setValue(b, forKey: "comment")
            }
        }
        let tags = NSMutableSet()
        for tagString in (item["tags"] as? [String])! {
            let tag = Tag.name(tagString, inManagedObjectContext: moc)
            tags.add(tag)
        }
        bookmark.setValue(tags, forKey: "tags")

        return bookmark
    }

    func newBookmark(moc: NSManagedObjectContext, item: [String: Any]) -> Bookmark? {
        guard let bookmarkUrl = item["bookmarkUrl"] as? String else { return nil }
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
        request.predicate = NSPredicate(format: "bookmarkUrl == %@", bookmarkUrl)
        do {
            guard let fetchedBookmarks = try moc.fetch(request) as? [Bookmark] else {
                preconditionFailure("Fetched object must be [Bookmark]")
            }
            if fetchedBookmarks.count > 0 { // exists, so update
                updateBookmark(moc: moc, fetchedBookmarks: fetchedBookmarks, item: item)
            } else { // does not exsist, so create
                return createBookmark(moc: moc, item: item)
            }
        } catch {
            fatalError("Failed to fetch bookmarks: \(error)")
        }
        return nil
    }

    func notifyNewObjects(_ bookmarks: [Bookmark]) {
        for bookmark: Bookmark in bookmarks {
            let notification = NSUserNotification()
            if let creator = bookmark.user?.name {
                notification.title = "\(creator) がブックマークを追加しました"
            }

            if let title = bookmark.page?.title, let count = bookmark.page?.count {
                var countString = ""
                if let enabled = UserDefaults.standard.value(forKey: "includeBookmarkCount") as? Bool, enabled {
                    countString = " [\(count) users]"
                }
                notification.subtitle = "\(title)\(countString)"
                notification.informativeText = bookmark.comment
            }

            bookmark.page?.computeComputedProperties { (_: Bool) in
                notification.contentImage = bookmark.page?.entryImage?.squared

                if let url = bookmark.bookmarkUrl {
                    notification.userInfo = ["bookmarkUrl": url]
                }

                NSUserNotificationCenter.default.deliver(notification)
            }
        }
    }

    @IBAction func reload(_: AnyObject) {
        perform()
    }

    @IBAction func openInBrowser(_: AnyObject) {
        guard let array = bookmarkArrayController.selectedObjects as? [Bookmark] else {
            preconditionFailure("selectedObjects must be Bookmark")
        }
        if array.count > 0 {
            if let bookmark = array.first, let urlString = bookmark.page?.url, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @IBAction override func quickLookPreviewItems(_: Any?) {
        let indexes = tableView.selectedRowIndexes
        if indexes.count > 0 {
            performSegueQuickLook()
        }
    }

    @IBAction func openBookmarkPageInBrowser(_: AnyObject) {
        guard let array = bookmarkArrayController.selectedObjects as? [Bookmark] else {
            preconditionFailure("selectedObjects must be Bookmark")
        }
        if array.count > 0 {
            if let bookmark = array.first, let urlString = bookmark.page?.url, let url = URL(string: "https://b.hatena.ne.jp/entry/\(urlString)") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @IBAction func openUserPageInBrowser(_: AnyObject) {
        guard let array = bookmarkArrayController.selectedObjects as? [Bookmark] else {
            preconditionFailure("selectedObjects must be Bookmark")
        }
        if array.count > 0 {
            if let bookmark = array.first, let name = bookmark.user?.name, let url = URL(string: "https://b.hatena.ne.jp/\(name)/") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @IBAction func updateSearchString(_ sender: AnyObject) {
        guard let field = sender as? NSSearchField else {
            preconditionFailure("sender must be NSSearchField")
        }
        let s = field.stringValue
        bookmarkArrayController.filterPredicate = { () -> NSPredicate? in
            if s == "" {
                return nil
            } else {
                return NSPredicate(format: "(page.title contains[c] %@) OR (comment contains[c] %@) OR (user.name contains[c] %@)", s, s, s)
            }
        }()
    }

    @IBAction func showComments(_: AnyObject) {
        let indexes = tableView.selectedRowIndexes
        if indexes.count > 0 {
            performSegueShowComments()
        }
    }

    @IBAction func showSharingServicePicker(_ sender: AnyObject) {
        guard let view = sender as? NSView else {
            preconditionFailure("sender must be NSView")
        }
        if let array = bookmarkArrayController.selectedObjects as? [Bookmark] {
            if array.count > 0 {
                if let bookmark = array.first, let title = bookmark.page?.title, let url = URL(string: bookmark.page?.url ?? "") {
                    let sharingServicePicker = NSSharingServicePicker(items: [title, url])
                    sharingServicePicker.show(relativeTo: sender.bounds, of: view, preferredEdge: NSRectEdge.minY)
                }
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
        if let identifierString = segue.identifier,
           let identifier = SegueIdentifier(rawValue: identifierString)
        { // TODO: 変換に失敗したときはログにだすべき
            switch identifier {
            case .quickLook:
                guard let tps = segue as? TablePopoverSegue else {
                    preconditionFailure("segue must be TablePopoverSegue")
                }
                tps.preferredEdge = NSRectEdge.maxX
                tps.popoverBehavior = .transient
                tps.anchorTableView = tableView
                let indexes = tableView.selectedRowIndexes
                if indexes.count > 0 {
                    if let objects = bookmarkArrayController.arrangedObjects as? [AnyObject], let bookmark = objects[indexes.first!] as? Bookmark {
                        let vc = segue.destinationController as? QuickLookWebViewController
                        vc?.representedObject = bookmark.page?.url
                    }
                }
            case .showComments:
                guard let tps = segue as? TablePopoverSegue else {
                    preconditionFailure("segue must be TablePopoverSegue")
                }
                tps.preferredEdge = NSRectEdge.maxX
                tps.popoverBehavior = .transient
                tps.anchorTableView = tableView
                let indexes = tableView.selectedRowIndexes
                if indexes.count > 0 {
                    if let objects = bookmarkArrayController.arrangedObjects as? [AnyObject], let bookmark = objects[indexes.first!] as? Bookmark {
                        let vc = segue.destinationController as? CommentsViewController
                        vc?.representedObject = bookmark.page?.url
                    }
                }
            case .showAccountSetting:
                break
            }
        }
    }

    func refresh() {
        tableView.reloadData()
    }

    @objc func updateData() {
        reload(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setup()
        perform()
    }

    // MARK: - Sign in/out

    @IBAction func performAuth(_: Any) {
        guard !QuestionBookmarkManager.shared.authorized else { return }
        let vc = QuestionAuthViewController.loadFromNib()
        presentAsModalWindow(vc)
        QuestionBookmarkManager.shared.authenticate(viewController: vc)
    }

    @IBAction func signOut(_: Any) {
        QuestionBookmarkManager.shared.signOut()
    }

    // MARK: - TableView

    /*
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

    func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for _: NSTableColumn?, row: Int) {
        if let c = cell as? NSTableRowView {
            if tableView.selectedRowIndexes.contains(row) {
                c.backgroundColor = NSColor.yellow
            } else {
                c.backgroundColor = NSColor.white
            }
            //        c.drawsBackground = true
        }
    }

    func tableView(_: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch _: String?) -> Bool {
        print(event.keyCode)
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tv = notification.object as? NSTableView {
            (view.window?.windowController as? MainWindowController)?.changeTabbarItemsWithState(tv.selectedRow >= 0)
        }
    }

    // MARK: - NSUserNotification

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let info = notification.userInfo as? [String: String] {
            if let bookmarkUrl = info["bookmarkUrl"] {
                let moc = managedObjectContext
                do {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
                    request.predicate = NSPredicate(format: "bookmarkUrl == %@", bookmarkUrl)
                    guard let results = try moc.fetch(request) as? [Bookmark] else {
                        preconditionFailure("Fetched object must be [Bookmark]")
                    }
                    if results.count > 0 {
                        bookmarkArrayController.setSelectedObjects(results)
                        NSAnimationContext.runAnimationGroup({ context in
                            context.allowsImplicitAnimation = true
                            self.tableView.scrollRowToVisible(self.tableView.selectedRow)
                        }, completionHandler: {
                            center.removeDeliveredNotification(notification)
                        })
                    }
                } catch {
                    fatalError("Failure: \(error)")
                }
            }
        }
    }

    // MARK: - performSegueHelper

    enum SegueIdentifier: String {
        case showAccountSetting = "ShowAccountSetting"
        case quickLook = "QuickLook"
        case showComments = "ShowComments"
    }

    func performSegueHelper(identifier: SegueIdentifier) {
        performSegue(withIdentifier: identifier.rawValue, sender: self)
    }

    func performSegueShowAccountSetting() {
        performSegueHelper(identifier: .showAccountSetting)
    }

    func performSegueQuickLook() {
        performSegueHelper(identifier: .quickLook)
    }

    func performSegueShowComments() {
        performSegueHelper(identifier: .showComments)
    }
}
