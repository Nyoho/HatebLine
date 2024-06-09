//
//  BookmarkInfoPanelController.swift
//  HatebLine
//

import Cocoa
import SwiftUI

class BookmarkInfoPanelController: NSWindowController {
    static let shared = BookmarkInfoPanelController()

    private let viewModel = BookmarkInfoViewModel()

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "情報"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.setFrameAutosaveName("BookmarkInfoPanel")

        super.init(window: panel)

        let hostingView = NSHostingView(rootView: BookmarkInfoView(viewModel: viewModel))
        panel.contentView = hostingView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggle() {
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                showWindow(nil)
                window.center()
            }
        }
    }

    func update(with bookmark: Bookmark?) {
        viewModel.update(with: bookmark)
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }
}
