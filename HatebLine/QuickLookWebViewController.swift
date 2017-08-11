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
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let urlString = representedObject as? String, let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.mainFrame.load(request)

            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(QuickLookWebViewController.progressNotification(_:)), name: NSNotification.Name.WebViewProgressStarted, object: nil)
            nc.addObserver(self, selector: #selector(QuickLookWebViewController.progressNotification(_:)), name: NSNotification.Name.WebViewProgressEstimateChanged, object: nil)
            nc.addObserver(self, selector: #selector(QuickLookWebViewController.progressNotification(_:)), name: NSNotification.Name.WebViewProgressFinished, object: nil)
        }
    }

    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
    }

    func progressNotification(_ notification: Notification) {
        switch notification.name {
        case NSNotification.Name.WebViewProgressStarted:
            progressIndicator.startAnimation(self)
            progressIndicator.alphaValue = 1
        case NSNotification.Name.WebViewProgressEstimateChanged:
            progressIndicator.doubleValue = webView.estimatedProgress
        case NSNotification.Name.WebViewProgressFinished:
            progressIndicator.stopAnimation(self)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.0
                self.progressIndicator.animator().alphaValue = 0
            }, completionHandler: nil)
        default:
            break
        }
    }
}
