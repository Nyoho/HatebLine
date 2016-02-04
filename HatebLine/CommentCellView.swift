//
//  CommentCellView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class CommentCellView: NSTableCellView {

    @IBOutlet weak var userNameField: NSTextField!
    @IBOutlet weak var profileImageView: NSImageView!
    @IBOutlet weak var dateField: NSTextField!
    @IBOutlet weak var commentField: NSTextField!
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let path = NSBezierPath()
        NSColor.lightGrayColor().set()
        path.lineWidth = 0.5
        path.moveToPoint(NSMakePoint(8, 0))
        path.lineToPoint(NSMakePoint(self.bounds.width-8, 0))
        path.stroke()
    }
    
}
