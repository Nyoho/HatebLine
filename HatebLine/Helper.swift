//
//  Helper.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/6.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import Cocoa

class Helper{

    static func commentWithTags(comment: String?, tags: [String]?) -> NSAttributedString? {
        let t = NSMutableAttributedString()
        if let s = comment {
            t.appendAttributedString(NSAttributedString(string: s))
        }
        if let set = tags {
            var first = true
            for tag in set {
                let space = t.isEqualToAttributedString(NSAttributedString()) ? "" : " "
                let comma = first ? "" : ","
                t.appendAttributedString(NSAttributedString(string: comma + space + "\(tag)", attributes: [NSForegroundColorAttributeName: NSColor.headerColor(), NSFontAttributeName: NSFont.systemFontOfSize(NSFont.smallSystemFontSize())]))
                first = false
            }
        }
        return t
    }

}