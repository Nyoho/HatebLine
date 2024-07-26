//
//  AcknowledgmentsViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/6.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class AcknowledgmentsViewController: NSViewController {
    @IBOutlet var textView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadRTF()
    }

    func loadRTF() {
        if let path = Bundle.main.path(forResource: "Acknowledgments", ofType: "rtf"),
           let data = FileManager.default.contents(atPath: path),
           let attrString = NSMutableAttributedString(rtf: data, documentAttributes: nil) {
            let range = NSRange(location: 0, length: attrString.length)
            attrString.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
            textView.textStorage?.setAttributedString(attrString)
        }
    }
}
