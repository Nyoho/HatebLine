//
//  Bookmark+CoreDataProperties.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/12.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Bookmark {

    @NSManaged var bookmarkUrl: String?
    @NSManaged var comment: String?
    @NSManaged var content: String?
    @NSManaged var count: NSNumber?
    @NSManaged var date: NSDate?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var user: User?

}
