//
//  SettingsManager.swift
//  barracuta
//
//  Created by samara on 1/14/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import UIKit

class SettingsManager {
    static let shared = SettingsManager()
    
    private init() {}
    
    static let didStaticHeadroomChange = Notification.Name("didFontSizeChange")
    
    private var _staticHeadroom: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didStaticHeadroomChange, object: nil) }
    }
    
    var staticHeadroom: Int {
        get { return _staticHeadroom ?? UserDefaults.standard.value(forKey: "staticHeadroom") as? Int ?? 512 }
        set {
            _staticHeadroom = newValue
            UserDefaults.standard.set(newValue, forKey: "staticHeadroom")
        }
    }
    
    var isBetaIos: Bool {
        get { return UserDefaults.standard.bool(forKey: "isBetaIos", defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: "isBetaIos") }
    }

    var verboseBoot: Bool {
        get { return UserDefaults.standard.bool(forKey: "verboseBoot", defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: "verboseBoot") }
    }
    
    var hideInternalText: Bool {
        get { return UserDefaults.standard.bool(forKey: "hideInternalText", defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: "hideInternalText") }
    }

    var puafPages: Bool {
        get { return UserDefaults.standard.bool(forKey: "puafPages", defaultValue: false) }
        set { UserDefaults.standard.set(newValue, forKey: "puafPages") }
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if let value = UserDefaults.standard.value(forKey: key) as? Bool {
            return value
        }
        return defaultValue
    }
}
extension SettingsManager {
    func resetToDefaultDefaults() {
        staticHeadroom = 512
        isBetaIos = false
        verboseBoot = true
        hideInternalText = true
        puafPages = false
    }
}
