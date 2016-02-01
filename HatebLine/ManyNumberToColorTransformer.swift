//
//  ManyNumberToColorTransformer.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/1.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

@objc(ManyNumberToColorTransformer) class ManyNumberToColorTransformer: NSValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let b = value?.boolValue {
            return b ? NSColor.redColor() : NSColor.blueColor()
        }
        return NSColor.grayColor()
    }
    
}
