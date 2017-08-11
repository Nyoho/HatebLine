//
//  WebViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/19.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController {

    @IBOutlet weak var webView: WebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override func viewWillAppear() {

        if let content = self.representedObject as? NSString {
            webView.mainFrame.loadHTMLString(content as String, baseURL: URL(string: ""))
        }
    }

    @IBAction func dismiss(_: AnyObject) {
        dismissViewController(self)
    }
}
