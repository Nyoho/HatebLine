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

class TimelineViewController: NSViewController, NSTableViewDelegate, NSUserNotificationCenterDelegate, NSMenuItemValidation {
    var parser: RSSParser!
    var parserOfMyFeed: RSSParser!
    @IBOutlet var tableView: NSTableView!
    var timer = Timer()
    private var composerObserver: NSObjectProtocol?

    // MARK: - Display Mode

    enum DisplayMode: Int {
        case bookmarks = 0
        case pages = 1
    }

    private var currentDisplayMode: DisplayMode = .bookmarks {
        didSet {
            if oldValue != currentDisplayMode {
                fetchAndApplySnapshot(animatingDifferences: true)
            }
        }
    }

    enum Section: Hashable {
        case main
        case page(NSManagedObjectID)
    }

    enum Item: Hashable {
        case bookmark(NSManagedObjectID)
        case pageHeader(NSManagedObjectID)
        case userInPage(NSManagedObjectID)
    }

    private var dataSource: NSTableViewDiffableDataSource<Section, Item>!
    private var currentBookmarks: [Bookmark] = []
    private var currentPageGroups: [PageGroup] = []

    struct PageGroup {
        let page: Page
        let bookmarks: [Bookmark]
        var latestBookmarkDate: Date? {
            bookmarks.compactMap { $0.date }.max()
        }
    }

    @objc lazy var persistentContainer = {
        (NSApplication.shared.delegate
           as! AppDelegate).persistentContainer
    }()

    @objc dynamic var managedObjectContext = (NSApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

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

        registerCellViews()
        setupDataSource()
        setupCoreDataObserver()
        setupAuthObserver()
        setupURLSchemeObserver()
    }

    private func registerCellViews() {
        let nib = NSNib(nibNamed: "PageGroupCellView", bundle: nil)
        tableView.register(nib, forIdentifier: NSUserInterfaceItemIdentifier("PageGroupCell"))
    }

    private func setupAuthObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthenticationRequired),
            name: .questionAuthenticationRequired,
            object: nil
        )
    }

    private func setupURLSchemeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenBookmarkComposerFromURL(_:)),
            name: .openBookmarkComposerFromURL,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowCommentsFromURL(_:)),
            name: .showCommentsFromURL,
            object: nil
        )
    }

    @objc private func handleOpenBookmarkComposerFromURL(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? URL else { return }
        let title = userInfo["title"] as? String

        DispatchQueue.main.async { [weak self] in
            self?.openBookmarkComposer(for: url, title: title)
        }
    }

    @objc private func handleShowCommentsFromURL(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? URL else { return }

        DispatchQueue.main.async { [weak self] in
            self?.showComments(for: url)
        }
    }

    private func showComments(for url: URL) {
        let storyboard = NSStoryboard(name: "Storyboard", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "CommentsViewController") as? CommentsViewController else {
            return
        }
        vc.representedObject = url.absoluteString

        let window = NSWindow(contentViewController: vc)
        window.title = "Comments"
        window.setContentSize(NSSize(width: 400, height: 500))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]

        let windowController = NSWindowController(window: window)
        windowController.showWindow(self)
    }

    @objc private func handleAuthenticationRequired() {
        DispatchQueue.main.async { [weak self] in
            QuestionBookmarkManager.shared.signOut {
                self?.performAuth(self as Any)
            }
        }
    }

    private func setupDataSource() {
        dataSource = NSTableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, tableColumn, row, item in
            guard let self = self else { return NSView() }

            switch item {
            case .bookmark(let objectID):
                guard let bookmark = self.currentBookmarks.first(where: { $0.objectID == objectID }) else {
                    return NSView()
                }
                let cellIdentifier = NSUserInterfaceItemIdentifier("BookmarkCell")
                guard let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? BookmarkCellView else {
                    return NSView()
                }
                cell.configure(with: bookmark)
                return cell

            case .pageHeader(let objectID):
                guard let pageGroup = self.currentPageGroups.first(where: { $0.page.objectID == objectID }) else {
                    return NSView()
                }
                let cellIdentifier = NSUserInterfaceItemIdentifier("PageGroupCell")
                guard let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? PageGroupCellView else {
                    return NSView()
                }
                cell.configure(with: pageGroup.page, bookmarks: pageGroup.bookmarks)
                return cell

            case .userInPage:
                return NSView()
            }
        }
    }

    private func setupCoreDataObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextObjectsDidChange(_:)),
            name: .NSManagedObjectContextObjectsDidChange,
            object: managedObjectContext
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    @objc private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context !== managedObjectContext,
              context.parent === managedObjectContext || context.persistentStoreCoordinator === managedObjectContext.persistentStoreCoordinator else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }

    @objc private func contextObjectsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.fetchAndApplySnapshot()
        }
    }

    private func applySnapshot(bookmarks: [Bookmark], animatingDifferences: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        switch currentDisplayMode {
        case .bookmarks:
            snapshot.appendSections([.main])
            snapshot.appendItems(bookmarks.map { .bookmark($0.objectID) })

        case .pages:
            for pageGroup in currentPageGroups {
                let section = Section.page(pageGroup.page.objectID)
                snapshot.appendSections([section])
                snapshot.appendItems([.pageHeader(pageGroup.page.objectID)], toSection: section)
            }
        }

        if animatingDifferences {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                dataSource.apply(snapshot, animatingDifferences: true)
            }
        } else {
            dataSource.apply(snapshot, animatingDifferences: false)
        }
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
            } else { // does not exist, so create
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
                if let url = bookmark.page?.entryImageUrl, let u = URL(string: url) {
                    // TODO: don't use synchronous loading
                    notification.contentImage = NSImage(fromURL: u)
                }

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

    @IBAction func displayModeChanged(_ sender: NSSegmentedControl) {
        currentDisplayMode = DisplayMode(rawValue: sender.selectedSegment) ?? .bookmarks
    }

    func setDisplayMode(_ index: Int) {
        currentDisplayMode = DisplayMode(rawValue: index) ?? .bookmarks
        NotificationCenter.default.post(name: .displayModeDidChange, object: self, userInfo: ["index": index])
    }

    @IBAction func selectDisplayModeFromMenu(_ sender: NSMenuItem) {
        setDisplayMode(sender.tag)
    }

    @IBAction func openInBrowser(_: AnyObject) {
        guard let bookmark = selectedBookmark(),
              let urlString = bookmark.page?.url,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction override func quickLookPreviewItems(_: Any?) {
        if tableView.selectedRow >= 0 {
            performSegueQuickLook()
        }
    }

    @IBAction func openBookmarkPageInBrowser(_: AnyObject) {
        guard let bookmark = selectedBookmark(),
              let urlString = bookmark.page?.url,
              let url = URL(string: "https://b.hatena.ne.jp/entry/\(urlString)") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction func openUserPageInBrowser(_: AnyObject) {
        guard let bookmark = selectedBookmark(),
              let name = bookmark.user?.name,
              let url = URL(string: "https://b.hatena.ne.jp/\(name)/") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction func updateSearchString(_ sender: AnyObject) {
        guard let field = sender as? NSSearchField else { return }
        let searchText = field.stringValue
        filterBookmarks(with: searchText)
    }

    private var searchText: String = ""

    private func filterBookmarks(with text: String) {
        searchText = text
        fetchAndApplySnapshot()
    }

    private func fetchAndApplySnapshot(animatingDifferences: Bool = true) {
        let request = NSFetchRequest<Bookmark>(entityName: "Bookmark")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        if !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "(page.title contains[c] %@) OR (comment contains[c] %@) OR (user.name contains[c] %@)",
                searchText, searchText, searchText
            )
        }

        do {
            let bookmarks = try managedObjectContext.fetch(request)
            currentBookmarks = bookmarks

            if currentDisplayMode == .pages {
                buildPageGroups(from: bookmarks)
            }

            applySnapshot(bookmarks: bookmarks, animatingDifferences: animatingDifferences)
        } catch {
            NSLog("Failed to fetch bookmarks: \(error)")
        }
    }

    private func buildPageGroups(from bookmarks: [Bookmark]) {
        var pageDict: [NSManagedObjectID: [Bookmark]] = [:]

        for bookmark in bookmarks {
            guard let page = bookmark.page else { continue }
            let pageID = page.objectID
            if pageDict[pageID] == nil {
                pageDict[pageID] = []
            }
            pageDict[pageID]?.append(bookmark)
        }

        var groups: [PageGroup] = []
        for (_, bookmarksInPage) in pageDict {
            guard let page = bookmarksInPage.first?.page else { continue }
            let sortedBookmarks = bookmarksInPage.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            groups.append(PageGroup(page: page, bookmarks: sortedBookmarks))
        }

        currentPageGroups = groups.sorted { ($0.latestBookmarkDate ?? .distantPast) > ($1.latestBookmarkDate ?? .distantPast) }
    }

    @IBAction func showComments(_: AnyObject) {
        if tableView.selectedRow >= 0 {
            performSegueShowComments()
        }
    }

    @IBAction func showSharingServicePicker(_ sender: AnyObject) {
        guard let view = sender as? NSView,
              let bookmark = selectedBookmark(),
              let title = bookmark.page?.title,
              let url = URL(string: bookmark.page?.url ?? "") else { return }
        let sharingServicePicker = NSSharingServicePicker(items: [title, url])
        sharingServicePicker.show(relativeTo: sender.bounds, of: view, preferredEdge: NSRectEdge.minY)
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
                if let bookmark = selectedBookmark() {
                    let vc = segue.destinationController as? QuickLookWebViewController
                    vc?.representedObject = bookmark.page?.url
                }
            case .showComments:
                guard let tps = segue as? TablePopoverSegue else {
                    preconditionFailure("segue must be TablePopoverSegue")
                }
                tps.preferredEdge = NSRectEdge.maxX
                tps.popoverBehavior = .transient
                tps.anchorTableView = tableView
                if let bookmark = selectedBookmark() {
                    let vc = segue.destinationController as? CommentsViewController
                    vc?.representedObject = bookmark.page?.url
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
        setup()
        fetchAndApplySnapshot(animatingDifferences: false)
        perform()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        tableView.sizeToFit()
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

    // MARK: - Bookmark Composer

    @IBAction func openBookmarkComposer(_: Any) {
        guard let bookmark = selectedBookmark(),
              let urlString = bookmark.page?.url,
              let url = URL(string: urlString) else { return }

        guard QuestionBookmarkManager.shared.authorized else {
            performAuth(self)
            return
        }

        do {
            let title = bookmark.page?.title
            let count = bookmark.page?.count
            let countText = count.map { "\($0) users" }
            let composer = try QuestionBookmarkManager.shared.makeBookmarkComposer(
                permalink: url,
                title: title,
                bookmarkCountText: countText
            )

            let observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let window = notification.object as? NSWindow,
                      window.contentViewController === composer else { return }
                self?.checkBookmarkAndUpdateTimeline(url: url)
            }
            composerObserver = observer

            presentAsModalWindow(composer)
        } catch {
            NSLog("Failed to open bookmark composer: \(error)")
        }
    }

    private func openBookmarkComposer(for url: URL, title: String?) {
        guard QuestionBookmarkManager.shared.authorized else {
            performAuth(self)
            return
        }

        do {
            let composer = try QuestionBookmarkManager.shared.makeBookmarkComposer(
                permalink: url,
                title: title,
                bookmarkCountText: nil
            )

            let observer = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let window = notification.object as? NSWindow,
                      window.contentViewController === composer else { return }
                self?.checkBookmarkAndUpdateTimeline(url: url)
            }
            composerObserver = observer

            presentAsModalWindow(composer)
        } catch {
            NSLog("Failed to open bookmark composer: \(error)")
        }
    }

    private func checkBookmarkAndUpdateTimeline(url: URL) {
        if let observer = composerObserver {
            NotificationCenter.default.removeObserver(observer)
            composerObserver = nil
        }
        QuestionBookmarkManager.shared.getMyBookmark(url: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.refreshMyFeed()
                case .failure(let error):
                    NSLog("Failed to get my bookmark: \(error)")
                    self?.removeBookmarkFromCoreData(pageUrl: url.absoluteString)
                }
            }
        }
    }

    private func refreshMyFeed() {
        guard let url = myFeedUrl() else { return }
        parserOfMyFeed.feedUrl = url
        DispatchQueue.global().async {
            self.parserOfMyFeed.parse { [weak self] items in
                self?.mergeBookmarks(items)
            }
        }
    }

    private func removeBookmarkFromCoreData(pageUrl: String) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmark")
        request.predicate = NSPredicate(format: "page.url == %@", pageUrl)
        do {
            guard let fetchedBookmarks = try managedObjectContext.fetch(request) as? [Bookmark] else { return }

            for bookmark in fetchedBookmarks {
                if bookmark.user?.name == QuestionBookmarkManager.shared.username {
                    managedObjectContext.delete(bookmark)
                }
            }
            if managedObjectContext.hasChanges {
                try managedObjectContext.save()
            }
        } catch {
            NSLog("Failed to remove bookmark from Core Data: \(error)")
        }
    }

    func selectedBookmark() -> Bookmark? {
        let row = tableView.selectedRow
        guard row >= 0, row < currentBookmarks.count else { return nil }
        return currentBookmarks[row]
    }

    private func isMyBookmarkSelected() -> Bool {
        guard let bookmark = selectedBookmark(),
              let userName = bookmark.user?.name,
              let myName = QuestionBookmarkManager.shared.username else { return false }
        return userName == myName
    }

    // MARK: - Delete Bookmark

    @IBAction func delete(_ sender: Any?) {
        guard isMyBookmarkSelected(),
              let bookmark = selectedBookmark(),
              let urlString = bookmark.page?.url,
              let url = URL(string: urlString) else { return }

        guard QuestionBookmarkManager.shared.authorized else {
            performAuth(self)
            return
        }

        QuestionBookmarkManager.shared.deleteMyBookmark(url: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.removeBookmarkFromCoreData(pageUrl: urlString)
                case .failure(let error):
                    NSSound.beep()
                    NSLog("Failed to delete bookmark: \(error)")
                }
            }
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(delete(_:)) {
            return isMyBookmarkSelected() && QuestionBookmarkManager.shared.authorized
        }
        if menuItem.action == #selector(selectDisplayModeFromMenu(_:)) {
            menuItem.state = (menuItem.tag == currentDisplayMode.rawValue) ? .on : .off
            return true
        }
        return true
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
        updateInfoPanelIfVisible()
    }

    // MARK: - Info Panel

    @IBAction func showInfoPanel(_ sender: Any?) {
        BookmarkInfoPanelController.shared.toggle()
        updateInfoPanelIfVisible()
    }

    private func updateInfoPanelIfVisible() {
        guard BookmarkInfoPanelController.shared.isVisible else { return }
        BookmarkInfoPanelController.shared.update(with: selectedBookmark())
    }

    // MARK: - NSUserNotification

    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        guard let info = notification.userInfo as? [String: String],
              let bookmarkUrl = info["bookmarkUrl"] else { return }

        if let index = currentBookmarks.firstIndex(where: { $0.bookmarkUrl == bookmarkUrl }) {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            NSAnimationContext.runAnimationGroup({ context in
                context.allowsImplicitAnimation = true
                self.tableView.scrollRowToVisible(index)
            }, completionHandler: {
                center.removeDeliveredNotification(notification)
            })
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
