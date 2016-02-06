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
    @IBOutlet weak var starImageView: NSImageView!
    var isPopular = false
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let path = NSBezierPath()
        NSColor.lightGrayColor().set()
        path.lineWidth = 0.5
        path.moveToPoint(NSMakePoint(8, 0))
        path.lineToPoint(NSMakePoint(self.bounds.width-8, 0))
        path.stroke()
        
        if isPopular {
            drawPopular()
        }
    }

    func drawPopular() {
        let size: CGFloat = 8.0
        let path = NSBezierPath()
        NSColor.orangeColor().setFill()
        path.moveToPoint(NSMakePoint(bounds.width, bounds.height))
        path.lineToPoint(NSMakePoint(bounds.width, bounds.height - 56.0))
        path.lineToPoint(NSMakePoint(bounds.width - size*3.0, bounds.height))
        path.lineToPoint(NSMakePoint(bounds.width, bounds.height))
        path.fill()
        
        if let context = NSGraphicsContext.currentContext() {
            let transform = NSAffineTransform()
            transform.translateXBy(bounds.width - size - 3.0, yBy: bounds.height - 3.0)
            transform.rotateByDegrees(-90.0)
            context.saveGraphicsState()
            transform.concat()
            var attr: [String: AnyObject]?
            attr = [NSFontAttributeName: NSFont.boldSystemFontOfSize(size), NSForegroundColorAttributeName: NSColor.whiteColor()]
            NSString(string: "Popular").drawAtPoint(NSMakePoint(0, 0), withAttributes: attr)
            
            context.restoreGraphicsState()
        }
    }
}
