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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    // Thx http://stackoverflow.com/questions/28187909/why-nstablecellview-backgroundstyle-is-never-set-to-nsbackgroundstyle-dark-for-s
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
            commentTextField?.textColor = NSColor.white
            titleTextField?.textColor = NSColor.controlColor
        } else {
            commentTextField?.textColor = NSColor.black
            titleTextField?.textColor = NSColor.selectedMenuItemColor
        }
    }
}
