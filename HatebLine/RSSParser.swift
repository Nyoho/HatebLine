//
//  RSSParser.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class RSSParser: NSObject, XMLParserDelegate {
    var feedUrl: URL

    var currentElementName: String!

    var parser = XMLParser()
    var elements = NSMutableDictionary()
    var element = NSString()
    var title = NSMutableString()
    var link = NSMutableString()
    var date = NSMutableString()
    var creator = NSMutableString()
    var content = NSMutableString()
    var count = NSMutableString()
    var comment = NSMutableString()
    var bookmarkUrl = String()
    var items = [[String: Any]]()
    var handler: (([[String: Any]]) -> Void)?
    var tag = NSMutableString()
    var tags: [String] = []

    init(url: URL) {
        feedUrl = url
    }

    func parse(completionHandler: @escaping ([[String: Any]]) -> Void) {
        items = [[String: Any]]()
        parser = XMLParser(contentsOf: feedUrl)!
        handler = completionHandler
        parser.delegate = self
        parser.parse()
    }

    func parserDidStartDocument(_: XMLParser) {
    }

    func parserDidEndDocument(_: XMLParser) {
        if let handler = handler {
            handler(items)
        }
    }

    func parser(_: XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes attributeDict: [String: String]) {
        element = elementName as NSString

        if elementName == "item" {
            bookmarkUrl = ""
            if let u = attributeDict["rdf:about"] {
                bookmarkUrl = u
            }
            elements = NSMutableDictionary()
            title = NSMutableString()
            date = NSMutableString()
            link = NSMutableString()
            creator = NSMutableString()
            content = NSMutableString()
            count = NSMutableString()
            comment = NSMutableString()
            tag = NSMutableString()
            tags = []
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        switch element {
        case "title":
            title.append(string)
        case "dc:date":
            date.append(string)
        case "link":
            link.append(string)
        case "dc:creator":
            creator.append(string)
        case "content:encoded":
            content.append(string)
        case "hatena:bookmarkcount":
            count.append(string)
        case "description":
            comment.append(string)
        case "dc:subject":
            tag.append(string)
        default:
            break
        }
    }

    func parser(_: XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        switch elementName {
        case "item":
            // print("[\(condenseWhitespace(count)) users] title: \(condenseWhitespace(title)) / date: \(condenseWhitespace(date)) / user: \(condenseWhitespace(creator)).")
            if !title.isEqual(nil) {
                elements["bookmarkUrl"] = bookmarkUrl
                elements["title"] = condenseWhitespace(title)
                elements["date"] = condenseWhitespace(date)
                elements["link"] = condenseWhitespace(link)
                elements["creator"] = condenseWhitespace(creator)
                elements["count"] = condenseWhitespace(count)
                elements["content"] = condenseWhitespace(content)
                elements["comment"] = condenseWhitespace(comment)
                elements["tags"] = tags
            }
            guard let elems = elements as? [String: Any] else {
                preconditionFailure("elements must be [String: Any]")
            }
            items.append(elems)
        case "dc:subject":
            tags.append(condenseWhitespace(tag) as String)
            tag = NSMutableString()
        default:
            break
        }
    }

    func condenseWhitespace(_ string: NSMutableString) -> NSString {
        return string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
    }
}
