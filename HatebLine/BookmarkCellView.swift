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
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    // Thx http://stackoverflow.com/questions/28187909/why-nstablecellview-backgroundstyle-is-never-set-to-nsbackgroundstyle-dark-for-s
    override var backgroundStyle: NSBackgroundStyle {
        set {
            if let rowView = self.superview as? NSTableRowView {
                super.backgroundStyle = rowView.selected ? NSBackgroundStyle.Dark : NSBackgroundStyle.Light
            } else {
                super.backgroundStyle = newValue
            }
            self.updateSelectionHighlight()
        }
        get {
            return super.backgroundStyle;
        }
    }
    
    func updateSelectionHighlight() {
        if ( self.backgroundStyle == NSBackgroundStyle.Dark ) {
            self.textField?.textColor = NSColor.whiteColor()
            self.commentTextField?.textColor = NSColor.whiteColor()
            self.titleTextField?.textColor = NSColor.controlColor()
        } else {
            self.textField?.textColor = NSColor.blackColor()
            self.commentTextField?.textColor = NSColor.blackColor()
            self.titleTextField?.textColor = NSColor.selectedMenuItemColor()
        }
    }

}
