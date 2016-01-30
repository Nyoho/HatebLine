//
//  Tag.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/30.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import CoreData


class Tag: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    class func name(name: String, inManagedObjectContext moc: NSManagedObjectContext) -> Tag {
        let tag: Tag
        do {
            let request = NSFetchRequest(entityName: "Tag")
            request.predicate = NSPredicate(format: "name == %@", name)
            let results = try moc.executeFetchRequest(request) as! [Tag]
            
            if (results.count > 0) {
                // Exist tag
                tag = results[0]
            } else {
                // Create tag
                tag = NSEntityDescription.insertNewObjectForEntityForName("Tag", inManagedObjectContext: moc) as! Tag
                tag.name = name
            }
        } catch {
            fatalError("Failure: \(error)")
        }
        return tag
    }
}
