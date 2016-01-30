//
//  RSSParser.swift
//  HatebLine
//
//  Created by 北䑓 如法 on 16/1/4.
//  Copyright © 2016年 北䑓 如法. All rights reserved.
//

import Cocoa

class RSSParser: NSObject, NSXMLParserDelegate {
    var feedUrl: NSURL? {
        if let n = userName {
            return NSURL(string:"http://b.hatena.ne.jp/\(n)/favorite.rss")!
//            return NSURL(string:"file:///tmp/favorite.rss")!
        } else {
            return nil
        }
    }

    var userName: String?
    
    var currentElementName : String!
    
    var parser = NSXMLParser()
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
    var items = NSMutableArray()
    var handler: (NSArray) -> Void = { a in }
    
    override init() {
        super.init()
    }
    
    func parse(completionHandler completionHandler: (NSArray) -> Void) -> Void {
        if let url = feedUrl {
            parser = NSXMLParser(contentsOfURL: url)!
            handler = completionHandler
            parser.delegate = self
            parser.parse()
        }
    }
    
    func parserDidStartDocument(parser: NSXMLParser) {
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        handler(items)
    }

    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        element = elementName
        
        if (elementName == "item") {
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
        }
    }

    func parser(parser: NSXMLParser, foundCharacters string: String){        
        switch element {
        case "title":
            title.appendString(string)
        case "dc:date":
            date.appendString(string)
        case "link":
            link.appendString(string)
        case "dc:creator":
            creator.appendString(string)
        case "content:encoded":
            content.appendString(string)
        case "hatena:bookmarkcount":
            count.appendString(string)
        case "description":
            comment.appendString(string)
        default:
            break
        }
    }

    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (elementName == "item") {
            //print("[\(condenseWhitespace(count)) users] title: \(condenseWhitespace(title)) / date: \(condenseWhitespace(date)) / user: \(condenseWhitespace(creator)).")
            if !title.isEqual(nil) {
                elements["bookmarkUrl"] = bookmarkUrl
                elements["title"] = condenseWhitespace(title)
                elements["date"] = condenseWhitespace(date)
                elements["link"] = condenseWhitespace(link)
                elements["creator"] = condenseWhitespace(creator)
                elements["count"] = condenseWhitespace(count)
                elements["content"] = condenseWhitespace(content)
                elements["comment"] = condenseWhitespace(comment)
            }
            items.addObject(elements)
        }
    }
    
    
    func condenseWhitespace(string: NSMutableString) -> NSString {
        return string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

}
