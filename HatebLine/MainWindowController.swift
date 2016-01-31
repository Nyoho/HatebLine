//
//  MainWindowController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/8.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {

    @IBOutlet weak var good:TimelineViewController? = nil
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.titleVisibility = .Hidden
    }

    // MARK: - NSWindowDelegate
    func windowDidEndLiveResize(notification: NSNotification) {
        let vc: TimelineViewController? = self.contentViewController as! TimelineViewController?
//        vc?.refresh()
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case "QuickLook":
            if let qvc = segue.destinationController as? QuickLookWebViewController {
                qvc.representedObject = ""
            }
        case "ShowWeb":
            let webvc = segue.destinationController as! WebViewController
            if let vc: TimelineViewController? = self.contentViewController as! TimelineViewController? {
                if let obj = vc?.bookmarkArrayController.selectedObjects.first as! Bookmark? {
                    print(vc?.bookmarkArrayController.selectedObjects.count)
                    print(obj.page?.title)
                    webvc.representedObject = obj.page?.content
                }
            }
        default:
            return
        }
    }
}
