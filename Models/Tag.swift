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
    class func name(_ name: String, inManagedObjectContext moc: NSManagedObjectContext) -> Tag {
        let tag: Tag
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tag")
            request.predicate = NSPredicate(format: "name == %@", name)
            let results = try moc.fetch(request) as! [Tag]
            
            if (results.count > 0) {
                // Exist tag
                tag = results[0]
            } else {
                // Create tag
                tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: moc) as! Tag
                tag.name = name
            }
        } catch {
            fatalError("Failure: \(error)")
        }
        return tag
    }
}
