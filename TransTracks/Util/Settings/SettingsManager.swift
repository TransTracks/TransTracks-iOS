//
//  SettingsManager.swift
//  TransTracks
//
//  Created by Cassie Wilson on 29/7/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import FirebaseAuth
import FirebaseFirestore
import UIKit

class SettingsManager {
    static let CODE_SALT = "iP5Rp315RpDq7gwpIUOcoeqicsxTtzzm"
    static let lockCodeDefault: String = ""
    
    //MARK: Lock Code
    
    static func getLockCode() -> String {
        return UserDefaultsUtil.getString(key: .lockCode)
    }
    
    static func setLockCode(newLockCode: String) {
        UserDefaultsUtil.setString(key: .lockCode, value: newLockCode)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setString(key: .lockCode, value: newLockCode)
        }
    }
    
    //MARK: Lock Delay

    static func getLockDelay() -> LockDelay {
        return UserDefaultsUtil.getEnum(key: .lockDelay, defaultValue: .defaultValue)
    }

    static func setLockDelay(_ newLockDelay: LockDelay) {
        setEnum(key: .lockDelay, value: newLockDelay)
    }
    
    //MARK: Lock Type
    
    static func getLockType() -> LockType {
        return UserDefaultsUtil.getEnum(key: .lockType, defaultValue: .defaultValue)
    }
    
    static func setLockType(_ newLockType: LockType) {
        setEnum(key: .lockType, value: newLockType)

        guard UIApplication.shared.supportsAlternateIcons else { return }

        let iconName:String?
        switch newLockType {
        case .off, .normal: iconName = nil
        case .trains: iconName = "AltAppIcon"
        }

        if iconName != UIApplication.shared.alternateIconName {
            UIApplication.shared.setAlternateIconName(iconName)
        }
    }
    
    //MARK: Show Ads
    
    static func showAds() -> Bool {
        return UserDefaultsUtil.getBool(key: .showAds, defaultValue: true)
    }

    static func setShowAds(_ newShowAds: Bool) {
       setBool(key: .showAds, value: newShowAds)
    }
    
    //MARK: Show Welcome

    static func showWelcome() -> Bool {
        return UserDefaultsUtil.getBool(key: .showWelcome, defaultValue: true)
    }

    static func setShowWelcome(_ newShowWelcome: Bool) {
        setBool(key: .showWelcome, value: newShowWelcome)
    }

    //MARK: Start Date

    static func getStartDate() -> Date {
        let startDate = UserDefaultsUtil.getDate(.startDate)

        if let startDate = startDate {
            return startDate
        } else {
            let newStartDate = Date.today()
            setStartDate(newStartDate)

            return newStartDate
        }
    }

    static func setStartDate(_ newStartDate: Date) {
        UserDefaultsUtil.setDate(key: .startDate, value: newStartDate)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setInt(key: .startDate, value: newStartDate.toEpochDay())
        }
    }
    
    //MARK: Theme
    
    static func getTheme() -> Theme {
        return UserDefaultsUtil.getEnum(key: .theme, defaultValue: .pink)
    }

    static func setTheme(_ newTheme: Theme) {
        setEnum(key: .theme, value: newTheme)
    }

    //MARK: User Last Seen

    public static func getUserLastSeen() -> Date {
        return UserDefaultsUtil.getDate(.userLastSeen) ?? Date()
    }

    public static func updateUserLastSeen() {
        UserDefaultsUtil.setDate(key: .userLastSeen, value: Date())
    }
    
    //MARK: Helpers
    
    private static func setBool(key: SettingsManager.Key, value: Bool) {
        UserDefaultsUtil.setBool(key: key, value: value)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setBool(key: key, value: value)
        }
    }
    
    private static func setEnum<T>(key: SettingsManager.Key, value: T) where T : RawRepresentable, T.RawValue == String {
        UserDefaultsUtil.setEnum(key: key, value: value)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setEnum(key: key, value: value)
        }
    }
    
    //MARK: Firebase handling
    
    static func enableFirebaseSync(){
        UserDefaultsUtil.setBool(key: .saveToFirebase, value: true)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.firebaseSettingUtil.addListener()
    }
    
    static func disableFirebaseSync(){
        UserDefaultsUtil.setBool(key: .saveToFirebase, value: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.firebaseSettingUtil.removeListener()
    }
    
    static func firebaseNeedsSetup(){
        disableFirebaseSync()
        
        if let user = Auth.auth().currentUser {
            attemptFirebaseAutoSetup()
        }
    }
    
    static func attemptFirebaseAutoSetup() {
        do {
            let docRef = try FirebaseSettingUtil.getSettingsDocRef()
                
            docRef.getDocument { (document, error) in
                if let document = document, document.exists, let data = document.data() {
                    var differences = [(Key, Any)]()
                    
                    Key.allCases.forEach { key in
                        if let value = data[key.rawValue] {
                            let isDifferent:Bool
                            
                            switch key {
                            case .lockCode: isDifferent = value is String && value as! String != getLockCode()
                            case .lockDelay: isDifferent = value is String && LockDelay(rawValue: value as! String) != nil && value as! String != getLockDelay().rawValue
                            case .lockType: isDifferent = value is String && LockType(rawValue: value as! String) != nil && value as! String != getLockType().rawValue
                            case .startDate: isDifferent = value is Int && value as! Int != getStartDate().toEpochDay()
                            case .theme: isDifferent = value is String && Theme(rawValue: value as! String) != nil && value as! String != getTheme().rawValue
                                
                            case .saveToFirebase, .showAds, .showWelcome, .userLastSeen: isDifferent = false
                            }
                            
                            if isDifferent {
                                differences.append((key, value))
                            }
                        } else if let value = firebaseValueForKey(key) {
                            docRef.setValue(value, forKey: key.rawValue)
                        }
                    }
                    
                    if differences.count == 0 {
                        setFirebaseDocument(docRef)
                    } else {
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        delegate.showSettingsConflictDialog(differences)
                    }
                } else {
                    setFirebaseDocument(docRef)
                }
            }
        } catch SettingsError.userNotLoggedIn {
            //Looks like we called this function at the wrong time, turn of the Firebase saving
            disableFirebaseSync()
        } catch {
            print(error)
        }
    }
    
    private static func setFirebaseDocument(_ docRef: DocumentReference) {
        var data: [String: Any] = [String: Any]()
        
        Key.allCases.forEach { key in
            if let value = firebaseValueForKey(key) {
                data[key.rawValue] = value
            }
        }
        
        docRef.setData(data)
        enableFirebaseSync()
    }
    
    static func firebaseValueForKey(_ key: Key) -> Any?{
        switch key {
        case .lockCode: return getLockCode()
        case .lockDelay: return getLockDelay().rawValue
        case .lockType: return getLockType().rawValue
        case .showAds: return showAds()
        case .showWelcome: return showWelcome()
        case .startDate: return getStartDate().toEpochDay()
        case .theme: return getTheme().rawValue
        case .saveToFirebase, .userLastSeen: return nil
        }
    }
    
    static func saveToFirebase() -> Bool {
        return UserDefaultsUtil.getBool(key: .saveToFirebase, defaultValue: false)
    }
    
    enum Key: String, CaseIterable {
        case lockCode
        case lockDelay
        case lockType
        case saveToFirebase
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
    
    static let defaultValue: LockType = .off
    
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
    
    static let defaultValue: LockDelay = .instant
    
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

enum SettingsError: Error {
    case documentDoesNotExist
    case userNotLoggedIn
}