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
    var isPopular = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath()
        NSColor.lightGray.set()
        path.lineWidth = 0.5
        path.move(to: NSPoint(x: 8, y: 0))
        path.line(to: NSMakePoint(bounds.width - 8, 0))
        path.stroke()

        if isPopular {
            drawPopular()
        }
    }

    func drawPopular() {
        let size: CGFloat = 8.0
        let path = NSBezierPath()
        NSColor.orange.setFill()
        path.move(to: NSMakePoint(bounds.width, bounds.height))
        path.line(to: NSMakePoint(bounds.width, bounds.height - 56.0))
        path.line(to: NSMakePoint(bounds.width - size * 3.0, bounds.height))
        path.line(to: NSMakePoint(bounds.width, bounds.height))
        path.fill()

        if let context = NSGraphicsContext.current {
            var transform = AffineTransform.identity
            transform.translate(x: bounds.width - size - 3.0, y: bounds.height - 3.0)
            transform.rotate(byDegrees: -90.0)
            context.saveGraphicsState()
            (transform as NSAffineTransform).concat()
            var attr: [NSAttributedString.Key: AnyObject]?
            attr = [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: size), NSAttributedString.Key.foregroundColor: NSColor.white]
            NSString(string: "Popular").draw(at: NSPoint(x: 0, y: 0), withAttributes: attr)

            context.restoreGraphicsState()
        }
    }
}
