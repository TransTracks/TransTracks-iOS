//
//  UserDefaultsUtil.swift
//  TransTracks
//
//  Created by Cassie Wilson on 16/2/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

class UserDefaultsUtil {
    static let CODE_SALT = "iP5Rp315RpDq7gwpIUOcoeqicsxTtzzm"
    
    //MARK: Lock Code
    
    static func getLockCode() -> String {
        return getString(.lockCode) ?? ""
    }
    
    static func setLockCode(newLockCode: String) {
        setAny(newLockCode, key: .lockCode)
    }
    
    //MARK: Lock Delay
    
    static func getLockDelay() -> LockDelay {
        let delayString = getString(.lockDelay) ?? LockDelay.instant.rawValue
        return LockDelay.init(rawValue: delayString) ?? LockDelay.instant
    }
    
    static func setLockDelay(_ newLockDelay: LockDelay) {
        setAny(newLockDelay.rawValue, key: .lockDelay)
    }
    
    //MARK: Lock Type
    
    static func getLockType() -> LockType {
        let typeString = getString(.lockType) ?? LockType.off.rawValue
        return LockType.init(rawValue: typeString) ?? LockType.off
    }
    
    static func setLockType(_ newLockType: LockType) {
        setAny(newLockType.rawValue, key: .lockType)
    }
    
    //MARK: Show Ads
    
    static func showAds() -> Bool {
        return getBool(.showAds) ?? true
    }
    
    static func setShowAds(_ newShowAds: Bool) {
        setAny(newShowAds, key: .showAds)
    }
    
    //MARK: Show Welcome
    
    static func showWelcome() -> Bool {
        return getBool(.showWelcome) ?? true
    }
    
    static func setShowWelcome(_ newShowWelcome: Bool) {
        setAny(newShowWelcome, key: .showWelcome)
    }
    
    //MARK: Start Date
    
    static func getStartDate() -> Date {
        let startDate = getDate(.startDate)
        
        if let startDate = startDate {
            return startDate
        } else {
            let newStartDate = Date()
            setStartDate(newStartDate)
            
            return newStartDate
        }
    }
    
    static func setStartDate(_ newStartDate: Date) {
        setAny(newStartDate, key: .startDate)
    }
    
    //MARK: Theme
    
    static func getTheme() -> Theme {
        let themeString = getString(.theme) ?? Theme.pink.rawValue
        return Theme(rawValue: themeString) ?? Theme.pink
    }
    
    static func setTheme(_ newTheme: Theme) {
        setAny(newTheme.rawValue, key: .theme)
    }
    
    //MARK: User Last Seen
    
    private static func getUserLastSeen() -> Date {
        return getDate(.userLastSeen) ?? Date()
    }
    
    private static func updateUserLastSeen() {
        setAny(Date(), key: .userLastSeen)
    }
    
    //MARK: Helper functions
    
    private static func getBool(_ key: Key) -> Bool? {
        let defaults = UserDefaults.standard
        let valueExists = defaults.object(forKey: key.rawValue) != nil
        
        if valueExists {
            return defaults.bool(forKey: key.rawValue)
        } else {
            return nil
        }
    }
    
    private static func getDate(_ key: Key) -> Date? {
        let defaults = UserDefaults.standard
        let value = defaults.object(forKey: key.rawValue)
        
        if let value = value {
            return value as? Date
        } else {
            return nil
        }
    }
    
    private static func getString(_ key: Key) -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: key.rawValue)
    }
    
    private static func setAny(_ value: Any?, key: Key) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key.rawValue)
    }
    
    private enum Key: String {
        case lockCode
        case lockDelay
        case lockType
        case showAds
        case showWelcome
        case startDate
        case theme
        case userLastSeen
    }
}

enum LockType: String, CaseIterable {
    case off
    case normal
    case trains
    
    func getDisplayName() -> String {
        switch self {
        case .off: return NSLocalizedString("disabled", comment: "")
        case .normal: return NSLocalizedString("enabledNormal", comment: "")
        case .trains: return NSLocalizedString("enabledTrains", comment: "")
        }
    }
    
    static func getDisplayNamesArray() -> [String] {
        return LockType.allCases.map{theme in theme.getDisplayName()}
    }
    
    func getIndex() -> Int {
        return LockType.allCases.firstIndex(of: self)!
    }
}

enum LockDelay: String, CaseIterable {
    case instant
    case oneMinute
    case twoMinutes
    case fiveMinutes
    case fifteenMinutes
    
    func getDisplayName() -> String {
        switch self {
        case .instant: return NSLocalizedString("instant", comment: "")
        case .oneMinute: return NSLocalizedString("oneMinute", comment: "")
        case .twoMinutes: return NSLocalizedString("twoMinutes", comment: "")
        case .fiveMinutes: return NSLocalizedString("fiveMinutes", comment: "")
        case .fifteenMinutes: return NSLocalizedString("fifteenMinutes", comment: "")
        }
    }
    
    static func getDisplayNamesArray() -> [String] {
        return LockDelay.allCases.map{theme in theme.getDisplayName()}
    }
    
    func getIndex() -> Int {
        return LockDelay.allCases.firstIndex(of: self)!
    }
}
