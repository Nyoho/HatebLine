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
import Alamofire

class Page: NSManagedObject {
    // Insert code here to add functionality to your managed object subclass
    var prepared: Bool = false
    var __favicon: NSImage? = nil
    var __entryImage: NSImage? = nil

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
                }
                r = match.range(at: 3)
                if r.length != 0 {
                    summary = (str as NSString).substring(with: r)
                }
                faviconUrl = (str as NSString).substring(with: match.range(at: 1))
                
                loadFaviconIfNeeded()
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

    var faviconUrl: String? = nil

    @objc dynamic var favicon: NSImage? {
        if let image = __favicon {
            return image
        } else {
            loadFaviconIfNeeded()
            return __favicon
        }
    }

    func loadFaviconIfNeeded(completion: ((NSImage?) -> Void)? = nil) {
        if let image = __favicon {
            completion?(image)
            return
        }

        guard let url = faviconUrl, let u = URL(string: url) else {
            completion?(nil)
            return
        }

        let objectID = self.objectID

        AF.request(u).response { [weak self] response in
            guard let self = self else {
                completion?(nil)
                return
            }

            // コンテキスト上で安全に実行
            guard let context = self.managedObjectContext else {
                completion?(nil)
                return
            }

            context.perform {
                // オブジェクトがまだ有効か確認
                guard context.registeredObject(for: objectID) != nil, !self.isDeleted else {
                    completion?(nil)
                    return
                }

                if let d = response.data, let image = NSImage(data: d) {
                    self.__favicon = image

                    completion?(image)

                    NotificationCenter.default.post(
                        name: Notification.Name("PageFaviconDidLoad"),
                        object: self,
                        userInfo: nil
                    )
                } else {
                    completion?(nil)
                }
            }
        }
    }

    @objc var summary: String?
    {
        willSet {
            self.willChangeValue(forKey: #keyPath(Page.summary))
        }
        didSet {
            self.didChangeValue(forKey: #keyPath(Page.summary))
        }
    }

    var entryImageUrl: String? = nil

    @objc dynamic var entryImage: NSImage? {
        if let image = __entryImage {
            return image
        } else {
            if let url = entryImageUrl, let u = URL(string: url) {
                let objectID = self.objectID
                AF.request(u).response { [weak self] response in
                    guard let self = self, let context = self.managedObjectContext else { return }
                    context.perform {
                        guard context.registeredObject(for: objectID) != nil, !self.isDeleted else { return }
                        if let d = response.data {
                            self.__entryImage = NSImage(data: d)
                        }
                    }
                }
            }
            return nil
        }
    }

    @objc var countString: String? {
        computeComputedProperties()
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
