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

import FirebaseAuth
import UIKit

class UserDefaultsUtil {
    static func setBool(key: SettingsManager.Key, value: Bool) {
        setAny(value, key: key)
    }
    
    static func getBool(key: SettingsManager.Key, defaultValue: Bool) -> Bool {
        let defaults = UserDefaults.standard
        let valueExists = defaults.object(forKey: key.rawValue) != nil

        if valueExists {
            return defaults.bool(forKey: key.rawValue)
        } else {
            return defaultValue
        }
    }
    
    static func setDate(key: SettingsManager.Key, value: Date){
        setAny(value, key: key)
    }
    
    static func getDate(_ key: SettingsManager.Key) -> Date? {
        let defaults = UserDefaults.standard
        let value = defaults.object(forKey: key.rawValue)

        if let value = value {
            return value as? Date
        } else {
            return nil
        }
    }
    
    static func setEnum<T>(key: SettingsManager.Key, value: T) where T : RawRepresentable, T.RawValue == String {
        setString(key: key, value: value.rawValue)
    }
    
    static func getEnum<T>(key: SettingsManager.Key, defaultValue: T) -> T where T : RawRepresentable, T.RawValue == String {
        return T(rawValue: getString(key: key)) ?? defaultValue
    }
    
    static func setString(key: SettingsManager.Key, value: String) {
        setAny(value, key: key)
    }
    
    static func getString(key: SettingsManager.Key) -> String {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: key.rawValue) ?? ""
    }
    
    private static func setAny(_ value: Any?, key: SettingsManager.Key) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key.rawValue)
    }
}
