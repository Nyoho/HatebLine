//
//  SafariExtensionHandler.swift
//  HatebLine for Safari
//
//  Created by 北䑓 如法 on 18/09/19.
//  Copyright © 2018 北䑓 如法. All rights reserved.
//

import Alamofire
import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
            switch messageName {
            case "DOMContentLoaded":
                if let url = properties?.url {
                    NSLog("DOMContentLoaded: (URL = \(url))")
                }
            default:
                NSLog("The extension received a message (\(messageName)) from a script injected into (\(String(describing: properties?.url))) with userInfo (\(userInfo ?? [:]))")
            }
        }
    }

    override func toolbarItemClicked(in _: SFSafariWindow) {}

    override func validateToolbarItem(in safariWindow: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        safariWindow.getActiveTab { safariTab in
            guard let safariTab = safariTab else {
                validationHandler(false, "")
                return
            }
            safariTab.getActivePage(completionHandler: { page in
                guard let page = page else {
                    validationHandler(false, "")
                    return
                }
                page.getPropertiesWithCompletionHandler { safariPageProperties in
                    if let url = safariPageProperties?.url {
                        AF.request("https://bookmark.hatenaapis.com/count/entry", method: .get, parameters: ["url": url], encoding: URLEncoding.default).response { response in
                            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                                switch str {
                                case "0":
                                    validationHandler(true, "")
                                default:
                                    validationHandler(true, "\(str)")
                                }
                            }
                        }
                    }
                }
            })
        }
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

    override func popoverWillShow(in _: SFSafariWindow) {}
}
