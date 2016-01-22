//
//  Page.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/22.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import CoreData
import Cocoa

class Page: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    var faviconUrl: String {
        guard let str = content else {
            return ""
        }
        do {
            let regex = try NSRegularExpression(pattern: "<cite><img.*?src=\"(.*?)\".*?>.*?</cite>(?:.*?<img src=\"(http.*?entryimage.*?)\".*?)?<p>(.*?)</p>", options: [.CaseInsensitive])
            
            let matches = regex.matchesInString(str as String, options: [], range: NSMakeRange(0, str.characters.count))
            if let match = matches.first {
                var r: NSRange
                r = match.rangeAtIndex(2)
                if r.length != 0 {
                    entryImageUrl = (str as NSString).substringWithRange(r)
                }
                r = match.rangeAtIndex(3)
                if r.length != 0 {
                    summary = (str as NSString).substringWithRange(r)
                }
                return (str as NSString).substringWithRange(match.rangeAtIndex(1))
            }
        } catch let error {
            print("\(error)")
        }
        return ""
    }
    
    var favicon: NSImage? {
        if let u = NSURL(string: faviconUrl) {
            return NSImage(contentsOfURL: u)
        } else {
            return nil
        }
    }
    
    var summary: String? = nil
    
    var entryImageUrl: String? = nil
    
    var entryImage: NSImage? {
        if let url = entryImageUrl, let u = NSURL(string: url) {
            return NSImage(contentsOfURL: u)
        } else {
            return nil
        }
    }
}
