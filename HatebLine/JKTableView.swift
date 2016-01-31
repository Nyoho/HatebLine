//
//  JKTableView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/22.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class JKTableView: NSTableView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func keyDown(theEvent: NSEvent) {
        var row = selectedRow
        switch theEvent.keyCode {
        case 38: // j
            row = row + 1
            selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            scrollRowToVisible(row)
            setNeedsDisplay()
        case 40: // k
            row = row - 1
            selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            scrollRowToVisible(row)
            setNeedsDisplay()
        case 49: // space
            delegate()?.performSelector("quickLookPreviewItems:", withObject: self)
        case 53: // esc
            selectRowIndexes(NSIndexSet(), byExtendingSelection: false)
        default:
            super.keyDown(theEvent)
            break
        }
    }
}
