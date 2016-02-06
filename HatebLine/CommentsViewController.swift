//
//  CommentsViewController.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/2/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa
import Himotoki
import Alamofire

class CommentsViewController: NSViewController {

    struct Comment: Decodable {
        let userName: String
        let comment: String?
        let date: NSDate?
        let tags: [String]?

        static func decode(e: Extractor) throws -> Comment {
            let dateFormatter = NSDateFormatter()
            let locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.locale = locale
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            dateFormatter.timeZone = NSTimeZone(abbreviation: "JST")
            let date = dateFormatter.dateFromString(try e <| "timestamp")!
            return try Comment(
                userName: e <| "user",
                comment: e <|? "comment",
                date: date,
                tags: e  <||? "tags"
            )
        }
    }
    
    struct Comments: Decodable {
        let comments: [Comment]
        let eid: String
        let entryUrl: String
        static func decode(e: Extractor) throws -> Comments {
            var eid = ""
            do {
                eid = try e <| "eid"
            } catch {
                let eidNum: Int = try e <| "eid"
                eid = String(eidNum)
            }
            return try build(self.init)(e <|| ["bookmarks"], eid, e <| "entry_url")
        }
    }
    
    var items = [Comment]()
    var populars = [Comment]()
    var eid = ""
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = representedObject as? String {
            parse(url)
        }
    }

    func parse(url: String) {
        progressIndicator.startAnimation(self)
        Alamofire.request(.GET, "http://b.hatena.ne.jp/entry/json/", parameters: ["url": url])
            .responseJSON { response in
                if let json = response.result.value {
                    let comments: Comments? = try? decode(json)
                    if let a = comments?.comments {
                        self.items.appendContentsOf(a)
                    }
                    if let e = comments?.eid {
                        self.eid = e
                    }
                    self.tableView.reloadData()
                    self.progressIndicator.stopAnimation(self)
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.3
                        self.progressIndicator.animator().alphaValue = 0
                        }, completionHandler: nil)
                }
        }
        Alamofire.request(.GET, "http://b.hatena.ne.jp/api/viewer.popular_bookmarks", parameters: ["url": url])
            .responseJSON { response in
                if let json = response.result.value {
                    let comments: Comments? = try? decode(json)
                    if let a = comments?.comments {
                        self.items.insertContentsOf(a, at: 0)
                        self.populars = a
                    }
                    self.tableView.reloadData()
                }
        }
    }

    // MARK: - TableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == "CommentColumn" {
            if let cell = tableView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentCellView,
                let item = items[row] as Comment? {
                    cell.isPopular = row < populars.count
                    cell.needsDisplay = true
                    cell.userNameField?.stringValue = item.userName
                    if let date = item.date {
                        cell.dateField?.stringValue = date.timeAgo
                    }
                    cell.commentField?.attributedStringValue = Helper.commentWithTags(item.comment, tags: item.tags) ?? NSAttributedString()

                    let twoLetters = (item.userName as NSString).substringToIndex(2)
                    Alamofire.request(.GET, "http://cdn1.www.st-hatena.com/users/\(twoLetters)/\(item.userName)/profile.gif")
                        .responseImage { response in
                            if let image = response.result.value {
//                                cell.profileImageView.wantsLayer = true
//                                cell.profileImageView?.layer?.cornerRadius = 5.0
                                cell.profileImageView?.image = image
                            }
                    }
                    
                    // star
                    if let date = item.date {
                        let formatter = NSDateFormatter()
                        formatter.dateFormat = "yyyyMMdd"
                        let dateString = formatter.stringFromDate(date)
                        let permalink = "http://b.hatena.ne.jp/\(item.userName)/\(dateString)#bookmark-\(eid)"
                        if let encodedString = permalink.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                            Alamofire.request(.GET, "http://s.st-hatena.com/entry.count.image?uri=\(encodedString)&q=1")
                                .responseImage { response in
                                    if let image = response.result.value {
                                        cell.starImageView?.image = image
                                    }
                            }
                        }
                    }
                    return cell
            }
        }
        return nil
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var heightOfRow: CGFloat = 48
        let item = items[row] as Comment
        if let cell = tableView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentCellView {
            tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: row))
            let size = NSMakeSize(tableView.tableColumns[0].width, 43.0);
            cell.commentField?.attributedStringValue = Helper.commentWithTags(item.comment, tags: item.tags) ?? NSAttributedString()
            cell.commentField?.preferredMaxLayoutWidth = size.width - (8+8+8+42)
            heightOfRow = cell.fittingSize.height
        }
        return heightOfRow < 48 ? 48 : heightOfRow
    }

}
