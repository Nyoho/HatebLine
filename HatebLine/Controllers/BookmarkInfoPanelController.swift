//
//  BookmarkInfoPanelController.swift
//  HatebLine
//

import Cocoa
import SwiftUI

class BookmarkInfoPanelController: NSWindowController {
    static let shared = BookmarkInfoPanelController()

    private let viewModel = BookmarkInfoViewModel()
    private static let frameKey = "BookmarkInfoPanelFrame"

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = NSLocalizedString("info.panelTitle", value: "Info", comment: "")
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false

        super.init(window: panel)

        let hostingView = NSHostingView(rootView: BookmarkInfoView(viewModel: viewModel))
        panel.contentView = hostingView

        restoreFrame()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidChangeFrame),
            name: NSWindow.didMoveNotification,
            object: panel
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidChangeFrame),
            name: NSWindow.didResizeNotification,
            object: panel
        )
    }

    @objc private func windowDidChangeFrame(_ notification: Notification) {
        saveFrame()
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
            }
        }
    }

    func update(with bookmark: Bookmark?) {
        viewModel.update(with: bookmark)
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    private func saveFrame() {
        guard let window = window else { return }
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: Self.frameKey)
    }

    private func restoreFrame() {
        guard let window = window,
              let frameString = UserDefaults.standard.string(forKey: Self.frameKey) else {
            window?.center()
            return
        }
        let frame = NSRectFromString(frameString)
        if frame.width > 0 && frame.height > 0 {
            window.setFrame(frame, display: false)
        } else {
            window.center()
        }
    }
}
