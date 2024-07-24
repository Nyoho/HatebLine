//
//  CommentsViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Alamofire
import Cocoa

class CommentsViewController: NSViewController {
    struct Comment: Codable {
        let userName: String
        let comment: String?
        let date: Date?
        let tags: [String]?

        enum CodingKeys: String, CodingKey {
            case userName = "user"
            case comment
            case timestamp
            case tags
        }
        
        init(userName: String, comment: String?, date: Date?, tags: [String]?) {
            self.userName = userName
            self.comment = comment
            self.date = date
            self.tags = tags
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userName = try container.decode(String.self, forKey: .userName)
            comment = try container.decodeIfPresent(String.self, forKey: .comment)
            tags = try container.decodeIfPresent([String].self, forKey: .tags)
            
            let timestamp = try container.decode(String.self, forKey: .timestamp)
            let dateFormatter = DateFormatter()
            let locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = locale
            dateFormatter.dateFormat = Self.containingSecondDate(timestamp) ? "yyyy/MM/dd HH:mm:ss" : "yyyy/MM/dd HH:mm"
            dateFormatter.timeZone = TimeZone(abbreviation: "JST")
            date = dateFormatter.date(from: timestamp)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(userName, forKey: .userName)
            try container.encodeIfPresent(comment, forKey: .comment)
            try container.encodeIfPresent(tags, forKey: .tags)
            
            if let date = date {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(abbreviation: "JST")
                let timestamp = dateFormatter.string(from: date)
                try container.encode(timestamp, forKey: .timestamp)
            }
        }

        static func containingSecondDate(_ string: String) -> Bool {
            // "yyyy/MM/dd HH:mm:ss" style?
            let regex = "(\\d{4}/(0[1-9]|1[0-2])/(0[1-9]|[12]\\d|3[01]))\\s*\\d+:\\d+:\\d+"
            guard let range = string.range(of: regex, options: .regularExpression, range: nil, locale: nil) else { return false }
            return !range.isEmpty
        }
    }

    struct Comments: Codable {
        let comments: [Comment]
        let eid: String
        let entryUrl: String

        enum CodingKeys: String, CodingKey {
            case comments = "bookmarks"
            case eid
            case entryUrl = "entry_url"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            comments = try container.decode([Comment].self, forKey: .comments)
            entryUrl = try container.decode(String.self, forKey: .entryUrl)
            
            // eidは文字列かIntの場合がある
            if let eidString = try? container.decode(String.self, forKey: .eid) {
                eid = eidString
            } else {
                let eidNum = try container.decode(Int.self, forKey: .eid)
                eid = String(eidNum)
            }
        }
    }

    enum Row {
        case sectionHeader(String)
        case comment(Comment, isPopular: Bool)
    }

    var rows = [Row]()
    var regulars = [Comment]()
    var allRegulars = [Comment]()
    var populars = [Comment]()
    var allPopulars = [Comment]()
    var eid = ""

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var progressIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = representedObject as? String {
            parse(url)
        }
    }

    func parse(_ url: String) {
        progressIndicator.startAnimation(self)
        AF.request("https://b.hatena.ne.jp/entry/json/", method: .get, parameters: ["url": url], encoding: URLEncoding.default)
            .responseDecodable(of: Comments.self) { response in
                switch response.result {
                case .success(let comments):
                    self.allRegulars = comments.comments
                    self.eid = comments.eid

                    AF.request("https://b.hatena.ne.jp/api/viewer.popular_bookmarks", parameters: ["url": url])
                        .responseDecodable(of: Comments.self) { response in
                            if let comments = response.value {
                                self.allPopulars = comments.comments
                            }
                            self.filter()
                            self.tableView.reloadData()
                            self.stopProgressIndicator()
                        }
                case .failure:
                    self.stopProgressIndicator()
                    self.showNoBookmarksMessage()
                }
            }
    }

    private func stopProgressIndicator() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.progressIndicator.animator().alphaValue = 0
            self.progressIndicator.stopAnimation(self)
        }, completionHandler: nil)
    }

    private func showNoBookmarksMessage() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("No bookmarks", comment: "")
        alert.informativeText = NSLocalizedString("This page has no bookmarks yet.", comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { _ in
                window.close()
            }
        }
    }

    func filter() {
        if UserDefaults.standard.bool(forKey: "IncludeNoComment") {
            populars = allPopulars
            regulars = allRegulars
        } else {
            populars = allPopulars.filter {
                !($0.comment ?? "").isEmpty || !($0.tags ?? []).isEmpty
            }
            regulars = allRegulars.filter {
                !($0.comment ?? "").isEmpty || !($0.tags ?? []).isEmpty
            }
        }

        rows.removeAll()
        if !populars.isEmpty {
            rows.append(.sectionHeader("Popular"))
            rows.append(contentsOf: populars.map { .comment($0, isPopular: true) })
        }
        if !regulars.isEmpty {
            rows.append(.sectionHeader("All Comments"))
            rows.append(contentsOf: regulars.map { .comment($0, isPopular: false) })
        }
    }

    @IBAction func updateFiltering(_: AnyObject) {
        filter()
        tableView.reloadData()
    }

    // MARK: - TableView

    @objc func numberOfRowsInTableView(_: NSTableView) -> Int {
        return rows.count
    }

    @objc func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        if case .sectionHeader = rows[row] {
            return true
        }
        return false
    }

    @objc func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .sectionHeader:
            return 24
        case .comment:
            return 72
        }
    }

    @objc func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch rows[row] {
        case .sectionHeader(let title):
            let cellIdentifier = NSUserInterfaceItemIdentifier("SectionHeaderCell")
            let cell: NSTableCellView
            if let existingCell = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView {
                cell = existingCell
            } else {
                cell = NSTableCellView()
                cell.identifier = cellIdentifier
                let textField = NSTextField(labelWithString: "")
                textField.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
                textField.textColor = NSColor.secondaryLabelColor
                textField.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(textField)
                cell.textField = textField
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                    textField.topAnchor.constraint(equalTo: cell.topAnchor, constant: 6),
                    textField.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -6)
                ])
            }
            cell.textField?.stringValue = title
            return cell

        case .comment(let item, _):
            guard tableColumn?.identifier.rawValue == "CommentColumn",
                  let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommentColumn"), owner: self) as? CommentCellView else {
                return nil
            }

            cell.userNameField?.stringValue = item.userName
            if let date = item.date {
                cell.dateField?.stringValue = date.timeAgo
            }
            cell.commentField?.attributedStringValue = Helper.commentWithTags(item.comment, tags: item.tags) ?? NSAttributedString()

            AF.request("https://cdn.profile-image.st-hatena.com/users/\(item.userName)/profile.gif")
                .responseImage { response in
                    if let image = response.value {
                        DispatchQueue.main.async {
                            cell.profileImageView?.image = image
                        }
                    }
                }

            // star
            if let date = item.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                let dateString = formatter.string(from: date)
                let permalink = "https://b.hatena.ne.jp/\(item.userName)/\(dateString)#bookmark-\(eid)"
                if let encodedString = permalink.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                    AF.request("https://s.st-hatena.com/entry.count.image?uri=\(encodedString)&q=1")
                        .responseImage { response in
                            if let image = response.value {
                                DispatchQueue.main.async {
                                    cell.starImageView?.image = image
                                }
                            }
                        }
                }
            }
            return cell
        }
    }

}
