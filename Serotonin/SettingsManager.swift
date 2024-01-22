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
    static let didPuafPagesChange = Notification.Name("didPuafPagesChange")
    static let didPuafMethodChange = Notification.Name("didPuafMethodChange")
    static let didkReadMethodChange = Notification.Name("didkReadMethodChange")
    static let didkWriteMethodChange = Notification.Name("didkWriteMethodChange")
    
    private var _staticHeadroom: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didStaticHeadroomChange, object: nil) }
    }
    
    private var _puafPages: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didPuafPagesChange, object: nil) }
    }
    
    private var _puafMethod: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didPuafMethodChange, object: nil) }
    }
    
    private var _kReadMethod: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didkReadMethodChange, object: nil) }
    }
    
    private var _kWriteMethod: Int? {
        didSet { NotificationCenter.default.post(name: SettingsManager.didkWriteMethodChange, object: nil) }
    }
    
    var staticHeadroom: Int {
        get { return _staticHeadroom ?? UserDefaults.standard.value(forKey: "staticHeadroom") as? Int ?? 512 }
        set {
            _staticHeadroom = newValue
            UserDefaults.standard.set(newValue, forKey: "staticHeadroom")
        }
    }
    
    var isBetaIos: Bool {
        get { return UserDefaults.standard.bool(forKey: "isBetaIos", defaultValue: isBetaiOS()) }
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

    var puafPages: Int {
        get { return _puafPages ?? UserDefaults.standard.value(forKey: "puafPages") as? Int ?? 3072 }
        set {
            _puafPages = newValue
            UserDefaults.standard.set(newValue, forKey: "puafPages")
        }
    }
    
    var puafMethod: Int {
        get { return _puafMethod ?? UserDefaults.standard.value(forKey: "puafMethod") as? Int ?? 2 }
        set {
            _puafMethod = newValue
            UserDefaults.standard.set(newValue, forKey: "puafMethod")
        }
    }
    
    var kreadMethod: Int {
        get { return _kReadMethod ?? UserDefaults.standard.value(forKey: "kreadMethod") as? Int ?? 1 }
        set {
            _kReadMethod = newValue
            UserDefaults.standard.set(newValue, forKey: "kreadMethod")
        }
    }
    
    var kwriteMethod: Int {
        get { return _kWriteMethod ?? UserDefaults.standard.value(forKey: "kwriteMethod") as? Int ?? 1 }
        set {
            _kWriteMethod = newValue
            UserDefaults.standard.set(newValue, forKey: "kwriteMethod")
        }
    }

    var useMemoryHogger: Bool {
        get { return UserDefaults.standard.bool(forKey: "useMemoryHogger", defaultValue: ((getPhysicalMemorySize() > UInt64(5369221120)))) } // 5 GB
        set { UserDefaults.standard.set(newValue, forKey: "useMemoryHogger") }
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
        verboseBoot = true
        hideInternalText = true
        useMemoryHogger = ((getPhysicalMemorySize() > UInt64(5369221120)))
        puafPages = 3072
        puafMethod = 2
        kwriteMethod = 1
        kreadMethod = 1
        isBetaIos = isBetaiOS()
    }
}
