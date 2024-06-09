//
//  User.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/11.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Alamofire
import Cocoa
import CoreData
import Foundation

class User: NSManagedObject {
    // Insert code here to add functionality to your managed object subclass
    var __profileImage: NSImage?

    @objc dynamic var profileImage: NSImage? {
        if let image = __profileImage {
            return image
        } else {
            if let n = name,
               let url = URL(string: "https://cdn.profile-image.st-hatena.com/users/\(n)/profile.gif") {
                    AF.request(url).response { response in
                        if let d = response.data {
                            self.willChangeValue(forKey: "profileImage")
                            self.__profileImage = NSImage(data: d)
                            self.didChangeValue(forKey: "profileImage")
                        }
                    }
            }
            return nil
        }
    }
}
