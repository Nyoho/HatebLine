//
//  Page+CoreDataProperties.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 17/7/19.
//  Copyright © 2017年 北䑓 如法. All rights reserved.
//

import CoreData
import Foundation

extension Page {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Page> {
        return NSFetchRequest<Page>(entityName: "Page")
    }

    @NSManaged var content: String?
    @NSManaged var count: NSNumber?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var bookmarks: NSSet?
}

// MARK: Generated accessors for bookmarks

extension Page {
    @objc(addBookmarksObject:)
    @NSManaged func addToBookmarks(_ value: Bookmark)

    @objc(removeBookmarksObject:)
    @NSManaged func removeFromBookmarks(_ value: Bookmark)

    @objc(addBookmarks:)
    @NSManaged func addToBookmarks(_ values: NSSet)

    @objc(removeBookmarks:)
    @NSManaged func removeFromBookmarks(_ values: NSSet)
}
