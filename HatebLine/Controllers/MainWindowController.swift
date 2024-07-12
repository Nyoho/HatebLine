//
//  MainWindowController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

extension NSToolbarItem.Identifier {
    static let displayModeGroup = NSToolbarItem.Identifier("DisplayModeGroup")
}

class MainWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    @IBOutlet var searchField: NSSearchField!
    @IBOutlet var shareButton: NSButton!
    var tableRowSelected: Bool = true

    private var displayModeGroup: NSToolbarItemGroup?
    private weak var storyboardToolbarDelegate: NSToolbarDelegate?

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.titleVisibility = .hidden
        shareButton.sendAction(on: NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseDown.rawValue))))

        setupDisplayModeToolbarItem()
        setupDisplayModeObserver()
    }

    private func setupDisplayModeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayModeDidChange(_:)),
            name: .displayModeDidChange,
            object: nil
        )
    }

    @objc private func handleDisplayModeDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let index = userInfo["index"] as? Int else { return }
        displayModeGroup?.selectedIndex = index
    }

    private func setupDisplayModeToolbarItem() {
        guard let toolbar = window?.toolbar else { return }

        storyboardToolbarDelegate = toolbar.delegate
        toolbar.delegate = self

        let group = NSToolbarItemGroup(itemIdentifier: .displayModeGroup, images: [
            NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "Bookmarks")!,
            NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "Pages")!
        ], selectionMode: .selectOne, labels: ["Bookmarks", "Pages"], target: self, action: #selector(displayModeChanged(_:)))
        group.label = "Display Mode"
        group.paletteLabel = "Display Mode"
        group.controlRepresentation = .collapsed
        group.selectedIndex = UserDefaults.standard.integer(forKey: "DisplayMode")
        displayModeGroup = group

        // DisplayModeSegmentedControl を削除
        if let index = toolbar.items.firstIndex(where: { $0.itemIdentifier.rawValue == "DisplayModeSegmentedControl" }) {
            toolbar.removeItem(at: index)
        }

        // DisplayModeGroup がなければ先頭に挿入
        if !toolbar.items.contains(where: { $0.itemIdentifier == .displayModeGroup }) {
            toolbar.insertItem(withItemIdentifier: .displayModeGroup, at: 0)
        }
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .displayModeGroup {
            return displayModeGroup
        }
        // Storyboard の delegate に転送
        return storyboardToolbarDelegate?.toolbar?(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers = storyboardToolbarDelegate?.toolbarAllowedItemIdentifiers?(toolbar) ?? []
        if !identifiers.contains(.displayModeGroup) {
            identifiers.append(.displayModeGroup)
        }
        return identifiers
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers = storyboardToolbarDelegate?.toolbarDefaultItemIdentifiers?(toolbar) ?? []
        // 先頭に displayModeGroup を追加
        if !identifiers.contains(.displayModeGroup) {
            identifiers.insert(.displayModeGroup, at: 0)
        }
        return identifiers
    }

    @objc private func displayModeChanged(_ sender: Any?) {
        let selectedIndex: Int
        if let group = sender as? NSToolbarItemGroup {
            selectedIndex = group.selectedIndex
        } else if let item = sender as? NSToolbarItem {
            selectedIndex = item.tag
        } else {
            return
        }

        if let vc = contentViewController as? TimelineViewController {
            vc.setDisplayMode(selectedIndex)
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidEndLiveResize(_: Notification) {
        //        let vc: TimelineViewController? = self.contentViewController as! TimelineViewController?
        //        vc?.refresh()
    }

    func changeTabbarItemsWithState(_ state: Bool) {
        tableRowSelected = state
    }

    override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case "QuickLook":
            if let qvc = segue.destinationController as? QuickLookWebViewController {
                qvc.representedObject = ""
            }
        case "ShowWeb":
            guard let webvc = segue.destinationController as? WebViewController else {
                preconditionFailure("segue.destinationController must be WebViewController")
            }
            if let vc = contentViewController as? TimelineViewController,
               let bookmark = vc.selectedBookmark()
            {
                webvc.representedObject = bookmark.page?.content
            }
        default:
            return
        }
    }

    @IBAction func performFindPanelAction(_ sender: AnyObject) {
        searchField.selectText(sender)
    }
}
