//
//  NSImage+Extension.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 18/??/??.
//  Copyright © 2018 北䑓 如法. All rights reserved.
//

import Cocoa
import Foundation

extension NSImage {
    var height: CGFloat { return size.height }
    var width: CGFloat { return size.width }

    var isLandscape: Bool { return width > height }
    var isPortrait: Bool { return height > width }

    // TODO: rewrite to retina support according to https://stackoverflow.com/questions/11949250/how-to-resize-nsimage/38442746
    var squared: NSImage? {
        let length = min(width, height)
        let x = floor((width - length) / 2)
        let y = floor((height - length) / 2)
        let srcRect = NSMakeRect(x, y, length, length)
        let distRect = NSMakeRect(0, 0, length, length)

        let squaredImage = NSImage(size: NSMakeSize(length, length))
        squaredImage.lockFocus()
        defer { squaredImage.unlockFocus() }
        draw(in: distRect, from: srcRect, operation: NSCompositingOperation.copy, fraction: 1.0, respectFlipped: false, hints: [:])

        return squaredImage
    }

    convenience init?(fromURL url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(data: data)
    }
}
