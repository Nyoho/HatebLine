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
    @IBOutlet weak var tokenExplanationLabel: NSTextField!
    
    override func viewDidLoad() {
        let text = NSLocalizedString("From link[rel=alternate] element in https://b.hatena.ne.jp/my/favorite", comment: "")
        
        let attributedString = NSMutableAttributedString(string: text)

        attributedString.addAttribute(.link, value: "https://b.hatena.ne.jp/my/favorite", range: (text as NSString).range(of: text))

        tokenExplanationLabel.isSelectable = true
        tokenExplanationLabel.allowsEditingTextAttributes = true
        tokenExplanationLabel.attributedStringValue = attributedString
        
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
