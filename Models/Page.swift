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

    @objc var favicon: NSImage? {
        guard let str = content else {
            return nil
        }
        if let image = self.__favicon {
            return image
        } else {
            DispatchQueue.global().async {
                do {
                    let regex = try NSRegularExpression(pattern: "<cite><img.*?src=\"(.*?)\".*?>.*?<\\/cite>.*?<img src=\"(.*?)\".*?<p>(.*?)<\\/p>", options: [.caseInsensitive, .dotMatchesLineSeparators])

                    let matches = regex.matches(in: str as String, options: [], range: NSMakeRange(0, str.count))
                    if let match = matches.first {
                        var r: NSRange
                        r = match.range(at: 2)
                        if r.length != 0 {
                            self.entryImageUrl = (str as NSString).substring(with: r)
                            if let url = self.entryImageUrl, let u = URL(string: url) {
                                self.__entryImage = NSImage(contentsOf: u)
                            }
                        }
                        r = match.range(at: 3)
                        if r.length != 0 {
                            self.willChangeValue(forKey: "summary")
                            self.__summary = (str as NSString).substring(with: r)
                            self.didChangeValue(forKey: "summary")
                        }
                        let faviconUrl = (str as NSString).substring(with: match.range(at: 1))
                        if let u = URL(string: faviconUrl) {
                            self.willChangeValue(forKey: "favicon")
                            self.__favicon = NSImage(contentsOf: u)
                            self.didChangeValue(forKey: "favicon")
                        }
                    }
                } catch let error {
                    print("\(error)")
                }
            }
        }
        return nil
    }

    @objc var summary: String? {
        return __summary
    }

    var entryImageUrl: String?

    @objc var entryImage: NSImage? {
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
