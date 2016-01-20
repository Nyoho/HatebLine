//
//  GrowingTextField.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/20.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class GrowingTextField: NSTextField {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    // Thank you, http://stackoverflow.com/questions/10463680/how-to-let-nstextfield-grow-with-the-text-in-auto-layout
    override var intrinsicContentSize: NSSize {
        if !self.cell!.wraps {
            return super.intrinsicContentSize
        }
        var frame = self.frame
        let width = frame.size.width
        frame.size.height = CGFloat.max
        let height = self.cell?.cellSizeForBounds(frame).height
        return NSMakeSize(width, height!);
    }
    
    // you need to invalidate the layout on text change, else it wouldn't grow by changing the text
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification)
        self.invalidateIntrinsicContentSize()
    }
}
