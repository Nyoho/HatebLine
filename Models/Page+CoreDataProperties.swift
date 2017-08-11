//
//  Page+CoreDataProperties.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 17/7/19.
//  Copyright © 2017年 北䑓 如法. All rights reserved.
//

import Foundation
import CoreData

extension Page {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Page> {
        return NSFetchRequest<Page>(entityName: "Page")
    }

    @NSManaged public var content: String?
    @NSManaged public var count: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var bookmarks: NSSet?
}

// MARK: Generated accessors for bookmarks
extension Page {

    @objc(addBookmarksObject:)
    @NSManaged public func addToBookmarks(_ value: Bookmark)

    @objc(removeBookmarksObject:)
    @NSManaged public func removeFromBookmarks(_ value: Bookmark)

    @objc(addBookmarks:)
    @NSManaged public func addToBookmarks(_ values: NSSet)

    @objc(removeBookmarks:)
    @NSManaged public func removeFromBookmarks(_ values: NSSet)
}
