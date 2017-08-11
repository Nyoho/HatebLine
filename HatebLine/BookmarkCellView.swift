//
//  BookmarkCellView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/6.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class BookmarkCellView: NSTableCellView {

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var commentTextField: NSTextField!
    @IBOutlet weak var countTextField: NSTextField!
    @IBOutlet weak var dateTextField: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    // Thx http://stackoverflow.com/questions/28187909/why-nstablecellview-backgroundstyle-is-never-set-to-nsbackgroundstyle-dark-for-s
    override var backgroundStyle: NSBackgroundStyle {
        set {
            if let rowView = self.superview as? NSTableRowView {
                super.backgroundStyle = rowView.isSelected ? NSBackgroundStyle.dark : NSBackgroundStyle.light
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
        if backgroundStyle == NSBackgroundStyle.dark {
            textField?.textColor = NSColor.white
            commentTextField?.textColor = NSColor.white
            titleTextField?.textColor = NSColor.controlColor
        } else {
            textField?.textColor = NSColor.black
            commentTextField?.textColor = NSColor.black
            titleTextField?.textColor = NSColor.selectedMenuItemColor
        }
    }
}
