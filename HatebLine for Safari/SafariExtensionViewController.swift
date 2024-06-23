//
//  SafariExtensionViewController.swift
//  HatebLine for Safari
//
//  Created by 北䑓 如法 on 18/09/19.
//  Copyright © 2018 北䑓 如法. All rights reserved.
//

import Alamofire
import AppKit
import SafariServices

class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width: 280, height: 120)
        return shared
    }()

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var urlLabel: NSTextField!
    @IBOutlet weak var bookmarkCountButton: NSButton!
    @IBOutlet weak var showCountCheckbox: NSButton!
    @IBOutlet weak var bookmarkButton: NSButton!
    @IBOutlet weak var showCommentsButton: NSButton!

    private var currentURL: URL?
    private var currentTitle: String?

    private static let showBookmarkCountKey = "showBookmarkCount"

    private var showBookmarkCount: Bool {
        get {
            // デフォルトはtrue
            if UserDefaults.standard.object(forKey: Self.showBookmarkCountKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Self.showBookmarkCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.showBookmarkCountKey)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showCountCheckbox?.state = showBookmarkCount ? .on : .off
        localizeUI()
    }

    private func localizeUI() {
        bookmarkButton?.title = NSLocalizedString("Bookmark", comment: "")
        showCommentsButton?.title = NSLocalizedString("Show Comments", comment: "")
        showCountCheckbox?.title = NSLocalizedString("Show bookmark count", comment: "")
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        loadCurrentPageInfo()
    }

    private func loadCurrentPageInfo() {
        SFSafariApplication.getActiveWindow { [weak self] window in
            window?.getActiveTab { tab in
                tab?.getActivePage { page in
                    page?.getPropertiesWithCompletionHandler { properties in
                        DispatchQueue.main.async {
                            self?.currentURL = properties?.url
                            self?.currentTitle = properties?.title
                            self?.titleLabel?.stringValue = properties?.title ?? ""
                            self?.urlLabel?.stringValue = properties?.url?.absoluteString ?? ""

                            if let url = properties?.url, self?.showBookmarkCount == true {
                                self?.loadBookmarkCount(for: url)
                            } else {
                                self?.bookmarkCountButton?.isHidden = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func loadBookmarkCount(for url: URL) {
        AF.request("https://bookmark.hatenaapis.com/count/entry",
                   method: .get,
                   parameters: ["url": url.absoluteString],
                   encoding: URLEncoding.default).response { [weak self] response in
            DispatchQueue.main.async {
                if let data = response.data,
                   let str = String(data: data, encoding: .utf8),
                   let count = Int(str), count > 0 {
                    self?.bookmarkCountButton?.title = "\(count) users"
                    self?.bookmarkCountButton?.isHidden = false
                } else {
                    self?.bookmarkCountButton?.isHidden = true
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func didPressButton(_: NSButton) {
        guard let url = currentURL else { return }
        openHatebLineComposer(for: url, title: currentTitle)
        dismissPopover()
    }

    @IBAction func showCommentsClicked(_ sender: NSButton) {
        guard let url = currentURL else { return }
        openHatebLineComments(for: url)
        dismissPopover()
    }

    @IBAction func bookmarkCountClicked(_ sender: NSButton) {
        guard let url = currentURL else { return }
        openHatebLineComments(for: url)
        dismissPopover()
    }

    @IBAction func showCountChanged(_ sender: NSButton) {
        showBookmarkCount = sender.state == .on
        if showBookmarkCount, let url = currentURL {
            loadBookmarkCount(for: url)
        } else {
            bookmarkCountButton?.isHidden = true
        }
    }

    // MARK: - HatebLine URL Scheme

    private func openHatebLineComposer(for url: URL, title: String?) {
        var components = URLComponents()
        components.scheme = "hatebline"
        components.host = "bookmark"
        components.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString)
        ]
        if let title = title {
            components.queryItems?.append(URLQueryItem(name: "title", value: title))
        }

        guard let hateblineURL = components.url else { return }
        NSWorkspace.shared.open(hateblineURL)
    }

    private func openHatebLineComments(for url: URL) {
        var components = URLComponents()
        components.scheme = "hatebline"
        components.host = "comments"
        components.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString)
        ]

        guard let hateblineURL = components.url else { return }
        NSWorkspace.shared.open(hateblineURL)
    }
}
