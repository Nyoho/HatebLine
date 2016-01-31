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
        if let urlString = representedObject as? String, let url = NSURL(string: urlString) {
            let request = NSURLRequest(URL: url)
            webView.mainFrame.loadRequest(request)

            let nc = NSNotificationCenter.defaultCenter()
            nc.addObserver(self, selector: "progressNotification:", name: WebViewProgressStartedNotification, object: nil)
            nc.addObserver(self, selector: "progressNotification:", name: WebViewProgressEstimateChangedNotification, object: nil)
            nc.addObserver(self, selector: "progressNotification:", name: WebViewProgressFinishedNotification, object: nil)
        }
    }
    
    override func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func progressNotification(notification: NSNotification) {
        switch notification.name {
        case WebViewProgressStartedNotification:
            progressIndicator.startAnimation(self)
            self.progressIndicator.alphaValue = 1
        case WebViewProgressEstimateChangedNotification:
            progressIndicator.doubleValue = webView.estimatedProgress
        case WebViewProgressFinishedNotification:
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
