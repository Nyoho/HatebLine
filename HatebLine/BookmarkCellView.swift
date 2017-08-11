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
            self.updateSelectionHighlight()
        }
        get {
            return super.backgroundStyle
        }
    }

    func updateSelectionHighlight() {
        if ( self.backgroundStyle == NSBackgroundStyle.dark ) {
            self.textField?.textColor = NSColor.white
            self.commentTextField?.textColor = NSColor.white
            self.titleTextField?.textColor = NSColor.controlColor
        } else {
            self.textField?.textColor = NSColor.black
            self.commentTextField?.textColor = NSColor.black
            self.titleTextField?.textColor = NSColor.selectedMenuItemColor
        }
    }

}
