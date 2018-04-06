//
//  Tag+CoreDataProperties.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/30.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import CoreData
import Foundation

extension Tag {
    @NSManaged var name: String?
    @NSManaged var bookmarks: NSSet?
}
