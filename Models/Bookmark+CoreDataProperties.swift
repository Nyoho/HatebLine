//
//  Bookmark+CoreDataProperties.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/22.
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
    @NSManaged var date: NSDate?
    @NSManaged var user: User?
    @NSManaged var page: Page?

}