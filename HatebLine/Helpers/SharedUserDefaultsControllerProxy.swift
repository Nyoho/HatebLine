//
//  SharedUserDefaultsControllerProxy.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/11.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//
//  Thx: https://stackoverflow.com/questions/29312106/xcode-6-os-x-storyboard-multiple-user-defaults-controllers-bug-with-multiple-sce

import Cocoa
import Foundation

@objc(SharedUserDefaultsControllerProxy)
open class SharedUserDefaultsControllerProxy: NSObject {
    lazy var defaults = NSUserDefaultsController.shared
}
