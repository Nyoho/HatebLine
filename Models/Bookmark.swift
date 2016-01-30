//
//  Bookmark.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/11.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import CoreData
import Cocoa

class Bookmark: NSManagedObject {

    var commentWithTags: NSAttributedString? {
        let t = NSMutableAttributedString()
        if let s = comment {
            t.appendAttributedString(NSAttributedString(string: s))
        }
        if let set = tags {
            var first = true
            for tag in set {
                let space = t.isEqualToAttributedString(NSAttributedString()) ? "" : " "
                let comma = first ? "" : ","
                t.appendAttributedString(NSAttributedString(string: comma + space + "\((tag as! Tag).name!)", attributes: [NSForegroundColorAttributeName: NSColor.secondaryLabelColor(), NSFontAttributeName: NSFont.systemFontOfSize(NSFont.smallSystemFontSize())]))
                first = false
            }
        }
        return t
    }

}
