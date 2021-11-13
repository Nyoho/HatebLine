//
//  GeneralPrefViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/11.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Question

class GeneralPrefViewController: NSViewController {
    @IBOutlet var usernameLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setUsername()
    }

    @IBAction func signin(_: Any) {
        guard !QuestionBookmarkManager.shared.authorized else { return }
        let vc = QuestionAuthViewController.loadFromNib()
        presentAsModalWindow(vc)
        QuestionBookmarkManager.shared.authenticate(viewController: vc)
    }

    @IBAction func signOut(_: Any) {
        QuestionBookmarkManager.shared.signOut()
    }

    func setUsername() {
        if QuestionBookmarkManager.shared.authorized, let name = QuestionBookmarkManager.shared.displayName {
            usernameLabel.stringValue = name
        } else {
            usernameLabel.stringValue = "(Not singed in yet)"
        }
    }
}
