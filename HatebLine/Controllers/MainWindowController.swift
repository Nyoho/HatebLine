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

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.titleVisibility = .hidden
        shareButton.sendAction(on: NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseDown.rawValue))))

        setupDisplayModeToolbarItem()
    }

    private func setupDisplayModeToolbarItem() {
        guard let toolbar = window?.toolbar else { return }

        toolbar.delegate = self

        let group = NSToolbarItemGroup(itemIdentifier: .displayModeGroup, images: [
            NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "Bookmarks")!,
            NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "Pages")!
        ], selectionMode: .selectOne, labels: ["Bookmarks", "Pages"], target: self, action: #selector(displayModeChanged(_:)))
        group.label = "Display Mode"
        group.paletteLabel = "Display Mode"
        group.controlRepresentation = .collapsed
        group.selectedIndex = 0
        displayModeGroup = group

        if let index = toolbar.items.firstIndex(where: { $0.itemIdentifier.rawValue == "DisplayModeSegmentedControl" }) {
            toolbar.removeItem(at: index)
            toolbar.insertItem(withItemIdentifier: .displayModeGroup, at: index)
        }
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == .displayModeGroup {
            return displayModeGroup
        }
        return nil
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.displayModeGroup]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return []
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
