//
//  Preferences.swift
//  Status
//
//  Created by Pierluigi Galdi on 18/01/2020.
//  Copyright © 2020 Pierluigi Galdi. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let shouldReloadStatusWidget = NSNotification.Name("shouldReloadStatusWidget")
}

internal struct Preferences {
    internal enum Keys: String {
        // Status items
        case shouldShowLangItem
        case shouldShowWifiItem
        case shouldShowPowerItem
        case shouldShowBatteryIcon
        case shouldShowBatteryPercentage
        case shouldShowDateItem
        case timeFormatTextField
        // GIF
        case shouldShowGif
        case gifSourceType    // Int  — 0 = file, 1 = url
        case gifFilePath      // String
        case gifURLString     // String
        case gifWidth         // Double
        case gifScalingMode   // Int  — 0 = fit, 1 = fill, 2 = stretch
    }

    static subscript<T>(_ key: Keys) -> T {
        get {
            guard let value = UserDefaults.standard.value(forKey: key.rawValue) as? T else {
                switch key {
                case .shouldShowLangItem:          return false as! T
                case .shouldShowWifiItem:          return true  as! T
                case .shouldShowPowerItem:         return true  as! T
                case .shouldShowBatteryIcon:       return true  as! T
                case .shouldShowBatteryPercentage: return false as! T
                case .shouldShowDateItem:          return true  as! T
                case .timeFormatTextField:         return "EE dd MMM HH:mm" as! T
                case .shouldShowGif:               return false as! T
                case .gifSourceType:               return 1     as! T   // URL
                case .gifFilePath:                 return ""    as! T
                case .gifURLString:                return ""    as! T
                case .gifWidth:                    return 60.0  as! T
                case .gifScalingMode:              return 0     as! T   // fit
                }
            }
            return value
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key.rawValue)
        }
    }

    static func reset() {
        Preferences[.shouldShowLangItem]          = false
        Preferences[.shouldShowWifiItem]          = true
        Preferences[.shouldShowPowerItem]         = true
        Preferences[.shouldShowBatteryIcon]       = true
        Preferences[.shouldShowBatteryPercentage] = false
        Preferences[.shouldShowDateItem]          = true
        Preferences[.timeFormatTextField]         = "EE dd MMM HH:mm"
        Preferences[.shouldShowGif]               = false
        Preferences[.gifSourceType]               = 1
        Preferences[.gifFilePath]                 = ""
        Preferences[.gifURLString]                = ""
        Preferences[.gifWidth]                    = 60.0
        Preferences[.gifScalingMode]              = 0
    }
}
