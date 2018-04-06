//
//  Helper.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/6.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Foundation

class Helper {
    static func commentWithTags(_ comment: String?, tags: [String]?) -> NSAttributedString? {
        let t = NSMutableAttributedString()
        if let s = comment {
            t.append(NSAttributedString(string: s))
        }
        if let set = tags {
            var first = true
            for tag in set {
                let space = t.isEqual(to: NSAttributedString()) ? "" : " "
                let comma = first ? "" : ","
                let attributes = [NSForegroundColorAttributeName: NSColor.headerColor, NSFontAttributeName: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize())]
                t.append(NSAttributedString(string: comma + space + "\(tag)", attributes: attributes))
                first = false
            }
        }
        return t
    }
}
