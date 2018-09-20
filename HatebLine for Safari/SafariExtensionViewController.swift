//
//  SafariExtensionViewController.swift
//  HatebLine for Safari
//
//  Created by 北䑓 如法 on 18/09/19.
//  Copyright © 2018 北䑓 如法. All rights reserved.
//

import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 320, height: 320)
        return shared
    }()

    @IBAction func didPressButton(_: NSButton) {
        print("Button pressed")
    }
}
