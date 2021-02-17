//
//  Page.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/22.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import CoreData
import Foundation

class Page: NSManagedObject {
    // Insert code here to add functionality to your managed object subclass
    var __favicon: NSImage?
    var __summary: String?
    var __entryImage: NSImage?
    var prepared: Bool = false

    public func computeComputedProperties(_ completion: ((Bool) -> Void)? = nil) {
        guard !prepared else {
            if let completion = completion {
                completion(true)
            }
            return
        }
        guard let str = content else {
            if let completion = completion {
                completion(true)
            }
            return
        }

        do {
            let regex = try NSRegularExpression(pattern: "<cite><img.*?src=\"(.*?)\".*?>.*?<\\/cite>.*?<img src=\"(.*?)\".*?<p>(.*?)<\\/p>", options: [.caseInsensitive, .dotMatchesLineSeparators])

            let matches = regex.matches(in: str as String, options: [], range: NSMakeRange(0, str.count))
            if let match = matches.first {
                var r: NSRange
                r = match.range(at: 2)
                if r.length != 0 {
                    entryImageUrl = (str as NSString).substring(with: r)
                    if let url = entryImageUrl, let u = URL(string: url) {
                        __entryImage = NSImage(fromURL: u) // NSImage(contentsOf: u)
                    }
                }
                r = match.range(at: 3)
                if r.length != 0 {
                    __summary = (str as NSString).substring(with: r)
                }
                let faviconUrl = (str as NSString).substring(with: match.range(at: 1))
                if let u = URL(string: faviconUrl) {
                    __favicon = NSImage(fromURL: u) // NSImage(contentsOf: u)
                }
            }
            prepared = true
        } catch {
            print("Error: \(error)")
            prepared = false
        }
        if let completion = completion {
            completion(prepared)
        }
    }

    @objc var favicon: NSImage? {
        computeComputedProperties()
        return __favicon
    }

    @objc var summary: String? {
        computeComputedProperties()
        return __summary
    }

    var entryImageUrl: String?

    @objc var entryImage: NSImage? {
        computeComputedProperties()
        return __entryImage
    }

    @objc var countString: String? {
        if let n = count {
            return n.intValue > 1 ? "\(n) users" : "\(n) user"
        } else {
            return ""
        }
    }

    @objc var manyBookmarked: Bool {
        guard let n = count else {
            return false
        }
        return n.intValue > 5 ? true : false
    }
}
