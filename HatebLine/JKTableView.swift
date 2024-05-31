//
//  JKTableView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/22.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class JKTableView: NSTableView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    override func keyDown(with theEvent: NSEvent) {
        var row = selectedRow
        switch theEvent.keyCode {
        case 38: // j
            row += 1
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            scrollRowToVisible(row)
            setNeedsDisplay()
        case 40: // k
            row -= 1
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            scrollRowToVisible(row)
            setNeedsDisplay()
        case 37: // l
            _ = delegate?.perform(#selector(TimelineViewController.openInBrowser(_:)), with: self)
        case 49: // space
            _ = delegate?.perform(#selector(NSResponder.quickLookPreviewItems(_:)), with: self)
        case 53: // esc
            selectRowIndexes(IndexSet(), byExtendingSelection: false)
        case 8: // c
            _ = delegate?.perform(#selector(TimelineViewController.showComments(_:)), with: self)
        case 11: // b
            _ = delegate?.perform(#selector(TimelineViewController.openBookmarkComposer(_:)), with: self)
        default:
            super.keyDown(with: theEvent)
        }
    }
}
