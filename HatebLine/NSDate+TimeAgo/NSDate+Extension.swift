//
//  NSDate+Extension.swift
//  Tasty
//
//  Created by Vitaliy Kuzmenko on 17/10/14.
//  http://github.com/vitkuzmenko
//  Copyright (c) 2014 Vitaliy Kuz'menko. All rights reserved.
//

import Foundation

func NSDateTimeAgoLocalizedStrings(_ key: String) -> String {
    let resourcePath: String?

    if let frameworkBundle = Bundle(identifier: "com.kevinlawler.NSDateTimeAgo") {
        // Load from Framework
        resourcePath = frameworkBundle.resourcePath
    } else {
        // Load from Main Bundle
        resourcePath = Bundle.main.resourcePath
    }

    if resourcePath == nil {
        return ""
    }

    let path = URL(fileURLWithPath: resourcePath!).appendingPathComponent("NSDateTimeAgo.bundle")
    guard let bundle = Bundle(url: path) else {
        return ""
    }

    return NSLocalizedString(key, tableName: "NSDateTimeAgo", bundle: bundle, comment: "")
}

extension Date {
    
    // shows 1 or two letter abbreviation for units.
    // does not include 'ago' text ... just {value}{unit-abbreviation}
    // does not include interim summary options such as 'Just now'
    public var timeAgoSimple: String {
        let components = self.dateComponents()

        if components.year! > 0 {
            return stringFromFormat("%%d%@yr", withValue: components.year!)
        }

        if components.month! > 0 {
            return stringFromFormat("%%d%@mo", withValue: components.month!)
        }

        // TODO: localize for other calanders
        if components.day! >= 7 {
            let value = components.day!/7
            return stringFromFormat("%%d%@w", withValue: value)
        }

        if components.day! > 0 {
            return stringFromFormat("%%d%@d", withValue: components.day!)
        }

        if components.hour! > 0 {
            return stringFromFormat("%%d%@h", withValue: components.hour!)
        }

        if components.minute! > 0 {
            return stringFromFormat("%%d%@m", withValue: components.minute!)
        }

        if components.second! > 0 {
            return stringFromFormat("%%d%@s", withValue: components.second! )
        }

        return ""
    }

    public var timeAgo: String {
        let components = self.dateComponents()

        if components.year! > 0 {
            if components.year! < 2 {
                return NSDateTimeAgoLocalizedStrings("Last year")
            } else {
                return stringFromFormat("%%d %@years ago", withValue: components.year!)
            }
        }

        if components.month! > 0 {
            if components.month! < 2 {
                return NSDateTimeAgoLocalizedStrings("Last month")
            } else {
                return stringFromFormat("%%d %@months ago", withValue: components.month!)
            }
        }

        // TODO: localize for other calanders
        if components.day! >= 7 {
            let week = components.day!/7
            if week < 2 {
                return NSDateTimeAgoLocalizedStrings("Last week")
            } else {
                return stringFromFormat("%%d %@weeks ago", withValue: week)
            }
        }

        if components.day! > 0 {
            if components.day! < 2 {
                return NSDateTimeAgoLocalizedStrings("Yesterday")
            } else  {
                return stringFromFormat("%%d %@days ago", withValue: components.day!)
            }
        }

        if components.hour! > 0 {
            if components.hour! < 2 {
                return NSDateTimeAgoLocalizedStrings("An hour ago")
            } else  {
                return stringFromFormat("%%d %@hours ago", withValue: components.hour!)
            }
        }

        if components.minute! > 0 {
            if components.minute! < 2 {
                return NSDateTimeAgoLocalizedStrings("A minute ago")
            } else {
                return stringFromFormat("%%d %@minutes ago", withValue: components.minute!)
            }
        }

        if components.second! > 0 {
            if components.second! < 5 {
                return NSDateTimeAgoLocalizedStrings("Just now")
            } else {
                return stringFromFormat("%%d %@seconds ago", withValue: components.second!)
            }
        }
        
        return ""
    }

    fileprivate func dateComponents() -> DateComponents {
        let calander = Calendar.current
        return (calander as NSCalendar).components([.second, .minute, .hour, .day, .month, .year], from: self, to: Date(), options: [])
    }

    fileprivate func stringFromFormat(_ format: String, withValue value: Int) -> String {
        let localeFormat = String(format: format, getLocaleFormatUnderscoresWithValue(Double(value)))
        return String(format: NSDateTimeAgoLocalizedStrings(localeFormat), value)
    }
    
    fileprivate func getLocaleFormatUnderscoresWithValue(_ value: Double) -> String {
        guard let localeCode = Locale.preferredLanguages.first else {
            return ""
        }
        
        // Russian (ru) and Ukrainian (uk)
        if localeCode == "ru" || localeCode == "uk" {
            let XY = Int(floor(value)) % 100
            let Y = Int(floor(value)) % 10

            if Y == 0 || Y > 4 || (XY > 10 && XY < 15) {
                return ""
            }

            if Y > 1 && Y < 5 && (XY < 10 || XY > 20) {
                return "_"
            }

            if Y == 1 && XY != 11 {
                return "__"
            }
        }
        
        return ""
    }
    
}

