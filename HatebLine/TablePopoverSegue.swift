//
//  TablePopoverSegue.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/31.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//  Thx: http://stackoverflow.com/questions/24353446/how-do-you-specify-the-origin-of-the-arrow-on-a-popover-segue-with-os-x-10-10-st

import Cocoa

class TablePopoverSegue: NSStoryboardSegue {
    
    @IBOutlet weak var anchorTableView: NSTableView!
    var preferredEdge: NSRectEdge!
    var popoverBehavior: NSPopoverBehavior!
    
    override func perform() {
        let selectedColumn = anchorTableView.selectedColumn
        let selectedRow = anchorTableView.selectedRow
        var anchorView = anchorTableView as NSView
        if (selectedRow >= 0) {
            if let view = anchorTableView.view(atColumn: selectedColumn, row: selectedRow, makeIfNecessary: false) {
                anchorView = view
            }
        }
        (sourceController as AnyObject).presentViewController(destinationController as! NSViewController, asPopoverRelativeTo: anchorView.bounds, of: anchorView, preferredEdge: preferredEdge, behavior: popoverBehavior)
    }

}
