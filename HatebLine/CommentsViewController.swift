//
//  CommentsViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Alamofire
import Cocoa
import Himotoki

class CommentsViewController: NSViewController {
    struct Comment: Himotoki.Decodable {
        let userName: String
        let comment: String?
        let date: Date?
        let tags: [String]?

        static func decode(_ e: Extractor) throws -> Comment {
            let timestamp: String = try e <| "timestamp"
            let dateFormatter = DateFormatter()
            let locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.locale = locale
            dateFormatter.dateFormat = containingSecondDate(timestamp) ? "yyyy/MM/dd HH:mm:ss" : "yyyy/MM/dd HH:mm"
            dateFormatter.timeZone = TimeZone(abbreviation: "JST")
            let date = dateFormatter.date(from: timestamp)
            return try Comment(
                userName: e <| "user",
                comment: e <|? "comment",
                date: date,
                tags: e <||? "tags"
            )
        }

        static func containingSecondDate(_ string: String) -> Bool {
            // "yyyy/MM/dd HH:mm:ss" style?
            let regex = "(\\d{4}/(0[1-9]|1[0-2])/(0[1-9]|[12]\\d|3[01]))\\s*\\d+:\\d+:\\d+"
            guard let range = string.range(of: regex, options: .regularExpression, range: nil, locale: nil) else { return false }
            return !range.isEmpty
        }
    }

    struct Comments: Himotoki.Decodable {
        let comments: [Comment]
        let eid: String
        let entryUrl: String
        static func decode(_ e: Extractor) throws -> Comments {
            var eid = ""
            do {
                eid = try e <| "eid"
            } catch {
                let eidNum: Int = try e <| "eid"
                eid = String(eidNum)
            }
            return try Comments(
                comments: e <|| ["bookmarks"],
                eid: eid,
                entryUrl: e <| "entry_url"
            )
        }
    }

    var items = [Comment]()
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
        Alamofire.request("http://b.hatena.ne.jp/entry/json/", method: .get, parameters: ["url": url], encoding: URLEncoding.default)
            .responseJSON { response in
                if let json = response.result.value {
                    let comments = try? Comments.decodeValue(json)
                    if let a = comments?.comments {
                        self.allRegulars = a
                    }
                    if let e = comments?.eid {
                        self.eid = e
                    }
                    Alamofire.request("http://b.hatena.ne.jp/api/viewer.popular_bookmarks", parameters: ["url": url])
                        .responseJSON { response in
                            if let json = response.result.value {
                                let comments: Comments? = try? decodeValue(json)
                                if let a = comments?.comments {
                                    self.allPopulars = a
                                }
                                self.filter()
                                self.tableView.reloadData()
                                NSAnimationContext.runAnimationGroup({ context in
                                    context.duration = 0.3
                                    self.progressIndicator.animator().alphaValue = 0
                                    self.progressIndicator.stopAnimation(self)
                                }, completionHandler: nil)
                            }
                        }
                }
            }
    }

    func filter() {
        if UserDefaults.standard.bool(forKey: "IncludeNoComment") {
            populars = allPopulars
            regulars = allRegulars
        } else {
            populars = allPopulars.filter {
                ($0.comment ?? "").isEmpty || !($0.tags ?? []).isEmpty
            }
            regulars = allRegulars.filter {
                !($0.comment ?? "").isEmpty || !($0.tags ?? []).isEmpty
            }
        }

        items = populars
        items.append(contentsOf: regulars)
    }

    @IBAction func updateFiltering(_: AnyObject) {
        filter()
        tableView.reloadData()
    }

    // MARK: - TableView

    @objc func numberOfRowsInTableView(_: NSTableView) -> Int {
        return items.count
    }

    @objc func tableView(_ tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "CommentColumn" {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommentColumn"), owner: self) as? CommentCellView,
                let item = items[row] as Comment? {
                cell.isPopular = row < populars.count
                cell.needsDisplay = true
                cell.userNameField?.stringValue = item.userName
                if let date = item.date {
                    cell.dateField?.stringValue = date.timeAgo
                }
                cell.commentField?.attributedStringValue = Helper.commentWithTags(item.comment, tags: item.tags) ?? NSAttributedString()

                let twoLetters = (item.userName as NSString).substring(to: 2)
                Alamofire.request("http://cdn1.www.st-hatena.com/users/\(twoLetters)/\(item.userName)/profile.gif")
                    .responseImage { response in
                        if let image = response.result.value {
                            DispatchQueue.main.async(execute: {
                                //                                cell.profileImageView.wantsLayer = true
                                //                                cell.profileImageView?.layer?.cornerRadius = 5.0
                                cell.profileImageView?.image = image
                            })
                        }
                    }

                // star
                if let date = item.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd"
                    let dateString = formatter.string(from: date)
                    let permalink = "http://b.hatena.ne.jp/\(item.userName)/\(dateString)#bookmark-\(eid)"
                    if let encodedString = permalink.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                        Alamofire.request("http://s.st-hatena.com/entry.count.image?uri=\(encodedString)&q=1")
                            .responseImage { response in
                                if let image = response.result.value {
                                    DispatchQueue.main.async(execute: {
                                        cell.starImageView?.image = image
                                    })
                                }
                            }
                    }
                }
                return cell
            }
        }
        return nil
    }

    @objc func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var heightOfRow: CGFloat = 48
        let item = items[row] as Comment
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommentColumn"), owner: self) as? CommentCellView {
            tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: row))
            let size = NSMakeSize(tableView.tableColumns[0].width, 43.0)
            cell.commentField?.attributedStringValue = Helper.commentWithTags(item.comment, tags: item.tags) ?? NSAttributedString()
            cell.commentField?.preferredMaxLayoutWidth = size.width - (8 + 8 + 8 + 42)
            heightOfRow = cell.fittingSize.height
        }
        return heightOfRow < 48 ? 48 : heightOfRow
    }
}
