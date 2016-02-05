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
        if let path = NSBundle.mainBundle().pathForResource("Acknowledgments", ofType: "rtf") {
            textView.readRTFDFromFile(path)
        }
    }
}
