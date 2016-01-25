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
    var __favicon: NSImage?
    var __summary: String?
    var __entryImage: NSImage?
    
    var favicon: NSImage? {
        guard let str = content else {
            return nil
        }
        if let image = self.__favicon {
            return image
        } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let regex = try NSRegularExpression(pattern: "<cite><img.*?src=\"(.*?)\".*?>.*?</cite>(?:.*?<img src=\"(http.*?entryimage.*?)\".*?)?<p>(.*?)</p>", options: [.CaseInsensitive])
                
                let matches = regex.matchesInString(str as String, options: [], range: NSMakeRange(0, str.characters.count))
                if let match = matches.first {
                    var r: NSRange
                    r = match.rangeAtIndex(2)
                    if r.length != 0 {
                        self.entryImageUrl = (str as NSString).substringWithRange(r)
                        if let url = self.entryImageUrl, let u = NSURL(string: url) {
                            self.__entryImage = NSImage(contentsOfURL: u)
                        }
                    }
                    r = match.rangeAtIndex(3)
                    if r.length != 0 {
                        self.willChangeValueForKey("summary")
                        self.__summary = (str as NSString).substringWithRange(r)
                        self.didChangeValueForKey("summary")
                    }
                    let faviconUrl = (str as NSString).substringWithRange(match.rangeAtIndex(1))
                    if let u = NSURL(string: faviconUrl) {
                        self.willChangeValueForKey("favicon")
                        self.__favicon = NSImage(contentsOfURL: u)
                        self.didChangeValueForKey("favicon")
                    }
                }
            } catch let error {
                print("\(error)")
            }
        })
        }
        return nil
    }

    
    var summary: String? {
        return __summary
    }
    
    var entryImageUrl: String? = nil
    
    var entryImage: NSImage? {
        return __entryImage
    }
    
    var countString: String? {
        if let n = count {
            return n.integerValue > 1 ? "\(n) users" : "\(n) user"
        } else {
            return ""
        }
    }
    
}
