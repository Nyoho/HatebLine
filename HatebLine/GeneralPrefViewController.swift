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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
}
