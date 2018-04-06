//
//  ManyNumberToColorTransformer.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/1.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

@objc(ManyNumberToColorTransformer) class ManyNumberToColorTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        if let b = (value as AnyObject).boolValue {
            return b ? NSColor.red : NSColor.blue
        }
        return NSColor.gray
    }
}
