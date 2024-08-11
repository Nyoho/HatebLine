//
//  BookmarkCellView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/6.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class BookmarkCellView: NSTableCellView {
    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var commentTextField: NSTextField!
    @IBOutlet var countTextField: NSTextField!
    @IBOutlet var dateTextField: NSTextField!
    @IBOutlet var faviconImageView: NSImageView!

    private var userObservation: NSKeyValueObservation?
    private var pageObservation: NSKeyValueObservation?
    private var faviconNotificationObserver: NSObjectProtocol?
    private(set) weak var bookmark: Bookmark?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView?.wantsLayer = true
        imageView?.layer?.cornerRadius = 24.0
        imageView?.layer?.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        userObservation = nil
        pageObservation = nil
        if let observer = faviconNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
            faviconNotificationObserver = nil
        }
        bookmark = nil
    }

    // Thx https://stackoverflow.com/questions/28187909/why-nstablecellview-backgroundstyle-is-never-set-to-nsbackgroundstyle-dark-for-s
    override var backgroundStyle: NSView.BackgroundStyle {
        set {
            if let rowView = superview as? NSTableRowView {
                super.backgroundStyle = rowView.isSelected ? NSView.BackgroundStyle.dark : NSView.BackgroundStyle.light
            } else {
                super.backgroundStyle = newValue
            }
            updateSelectionHighlight()
        }
        get {
            return super.backgroundStyle
        }
    }

    func updateSelectionHighlight() {
        if backgroundStyle == NSView.BackgroundStyle.dark {
            titleTextField?.textColor = NSColor.white
        } else {
            titleTextField?.textColor = NSColor.linkColor
        }
    }

    func configure(with bookmark: Bookmark) {
        self.bookmark = bookmark

        imageView?.image = bookmark.user?.profileImage
        textField?.stringValue = bookmark.user?.name ?? ""
        dateTextField?.stringValue = bookmark.timeAgo ?? ""
        commentTextField?.attributedStringValue = bookmark.commentWithTags ?? NSAttributedString()
        commentTextField?.isHidden = bookmark.isCommentEmpty
        titleTextField?.stringValue = bookmark.page?.title ?? ""
        faviconImageView?.image = bookmark.page?.favicon
        countTextField?.stringValue = bookmark.page?.countString ?? ""
        if bookmark.page?.manyBookmarked == true {
            countTextField?.font = NSFont.boldSystemFont(ofSize: countTextField.font?.pointSize ?? 12)
            countTextField?.textColor = NSColor.systemRed
        } else {
            countTextField?.font = NSFont.systemFont(ofSize: countTextField.font?.pointSize ?? 12)
            countTextField?.textColor = NSColor.labelColor
        }

        userObservation = bookmark.user?.observe(\.profileImage, options: [.new]) { [weak self] user, _ in
            DispatchQueue.main.async {
                self?.imageView?.image = user.profileImage
            }
        }

        pageObservation = bookmark.page?.observe(\.favicon, options: [.new]) { [weak self] page, _ in
            DispatchQueue.main.async {
                self?.faviconImageView?.image = page.favicon
            }
        }

        faviconNotificationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("PageFaviconDidLoad"),
            object: bookmark.page,
            queue: .main
        ) { [weak self] notification in
            guard let page = notification.object as? Page else { return }
            self?.faviconImageView?.image = page.favicon
        }
    }
}
