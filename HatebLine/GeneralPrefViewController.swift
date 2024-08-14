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
    @IBOutlet var signInButton: NSButton!
    @IBOutlet var signOutButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    @IBAction func signin(_: Any) {
        guard !QuestionBookmarkManager.shared.authorized else { return }
        let vc = QuestionAuthViewController.loadFromNib()
        presentAsSheet(vc)
        QuestionBookmarkManager.shared.authenticate(viewController: vc)
    }

    @IBAction func signOut(_: Any) {
        QuestionBookmarkManager.shared.signOut()
        updateUI()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateUI()
    }

    override func dismiss(_ viewController: NSViewController) {
        super.dismiss(viewController)
        updateUI()
    }

    private func updateUI() {
        let isAuthorized = QuestionBookmarkManager.shared.authorized

        signInButton?.isEnabled = !isAuthorized
        signOutButton?.isEnabled = isAuthorized

        if isAuthorized, let name = QuestionBookmarkManager.shared.displayName {
            usernameLabel?.stringValue = name
        } else {
            usernameLabel?.stringValue = "(Not signed in yet)"
        }
    }
}
