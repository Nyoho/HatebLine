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
    @IBOutlet var webView: WKWebView!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let urlString = representedObject as? String, let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
            
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        }
    }
    
    override func viewWillDisappear() {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.isLoading))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            assertionFailure()
            return
        }
        
        switch keyPath {
        case #keyPath(WKWebView.isLoading):
            if webView.isLoading {
                progressIndicator.startAnimation(self)
                progressIndicator.alphaValue = 1
            } else {
                progressIndicator.stopAnimation(self)
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 1.0
                    self.progressIndicator.animator().alphaValue = 0
                }, completionHandler: nil)
            }
        case #keyPath(WKWebView.estimatedProgress):
            progressIndicator.doubleValue = webView.estimatedProgress
        default:
            //do nothing
            break
        }
    }
    
}
