//
//  CommentCellView.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class CommentCellView: NSTableCellView {
    @IBOutlet var userNameField: NSTextField!
    @IBOutlet var profileImageView: NSImageView!
    @IBOutlet var dateField: NSTextField!
    @IBOutlet var commentField: NSTextField!
    @IBOutlet var starImageView: NSImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        profileImageView.wantsLayer = true
        profileImageView.layer?.cornerRadius = 21.0
        profileImageView.layer?.masksToBounds = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        NSColor.separatorColor.set()
        path.lineWidth = 0.5
        path.move(to: NSPoint(x: 8, y: 0))
        path.line(to: NSMakePoint(bounds.width - 8, 0))
        path.stroke()
    }
}
