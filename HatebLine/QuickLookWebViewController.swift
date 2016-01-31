//
//  QuickLookWebViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/31.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import WebKit

class QuickLookWebViewController: NSViewController {

    @IBOutlet weak var webView: WebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let urlString = representedObject as? String, let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            webView.mainFrame.loadRequest(request)
        }
    }
    
}
