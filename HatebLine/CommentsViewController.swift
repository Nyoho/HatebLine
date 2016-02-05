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
        let comment: String
        let date: NSDate?
//        let tags = []

        static func decode(e: Extractor) throws -> Comment {
            let dateFormatter = NSDateFormatter()
            let locale = NSLocale(localeIdentifier: "en_US_POSIX")
            dateFormatter.locale = locale
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            dateFormatter.timeZone = NSTimeZone(abbreviation: "JST")
            let date = dateFormatter.dateFromString(try e <| "timestamp")!
            return try Comment(
                userName: e <| "user",
                comment: e <| "comment",
                date: date
            )
        }
    }
    
    struct Comments: Decodable {
        let comments: [Comment]
        let eid: Int
        let entryUrl: String
        static func decode(e: Extractor) throws -> Comments {
            return try build(self.init)(e <|| ["bookmarks"], e <| "eid", e <| "entry_url")
        }
    }
    
    var items = [Comment]()
    var eid = 0
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = representedObject as? String {
            parse(url)
        }
    }

    func parse(url: String) {
        Alamofire.request(.GET, "http://b.hatena.ne.jp/entry/json/", parameters: ["url": url])
            .responseJSON { response in
                if let json = response.result.value {
                    let comments: Comments? = try? decode(json)
                    if let a = comments?.comments {
                        self.items = a
                    }
                    if let e = comments?.eid {
                        self.eid = e
                    }
                    self.tableView.reloadData()
                }
        }
//        let jsonPopular = JSON.fromURL("http://b.hatena.ne.jp/api/viewer.popular_bookmarks?url=\(url)")
    }

    // MARK: - TableView
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return items.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == "CommentColumn" {
            if let cell = tableView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentCellView,
                let item = items[row] as Comment? {
                    cell.userNameField?.stringValue = item.userName
                    if let date = item.date {
                        cell.dateField?.stringValue = date.timeAgo
                    }
                    cell.commentField?.stringValue = item.comment
                    
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
                            print("http://s.st-hatena.com/entry.count.image?uri=\(encodedString)&q=1")
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
            cell.commentField?.stringValue = item.comment
            cell.commentField?.preferredMaxLayoutWidth = size.width - (8+8+8+42)
            heightOfRow = cell.fittingSize.height
        }
        return heightOfRow < 48 ? 48 : heightOfRow
    }

}
