//
//  User.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/11.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Foundation
import CoreData
import Alamofire
import Cocoa

class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    var profileImage: NSImage?  {
        var newImage: NSImage?
        if let n = name {
            let twoLetters = (n as NSString).substringToIndex(2)
            let url = NSURL(string: "http://cdn1.www.st-hatena.com/users/\(twoLetters)/\(n)/profile.gif")
            let data = NSData(contentsOfURL: url!)
            newImage =  NSImage(data: data!)!
            return newImage!
        } else {
            return nil
        }
    }

}
