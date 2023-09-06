//
//  SettingsManager.swift
//  TransTracks
//
//  Created by Cassie Wilson on 29/7/19.
//  Copyright © 2019-2022 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//


import FirebaseAuth
import FirebaseCrashlytics
import Firebase
import FirebaseFirestore
import UIKit

class SettingsManager {
    static let CODE_SALT = "iP5Rp315RpDq7gwpIUOcoeqicsxTtzzm"
    static let lockCodeDefault: String = ""
    
    // MARK: Current iOS Version
    
    public static func getCurrentiOSVersion() -> Int? {
        return UserDefaultsUtil.getInt(key: .currentiOSVersion)
    }
    
    public static func updateCurrentiOSVersion() {
        let buildVersion = Int(Bundle.main.buildVersionNumber!)!
        UserDefaultsUtil.setInt(key: .currentiOSVersion, value: buildVersion)
    }
    
    // MARK: Incorrect Password Count
    
    public static func getIncorrectPasswordCount() -> Int {
        return UserDefaultsUtil.getInt(key: .incorrectPasswordCount) ?? 0
    }
    
    public static func incrementIncorrectPasswordCount() {
        UserDefaultsUtil.setInt(key: .incorrectPasswordCount, value: getIncorrectPasswordCount() + 1)
    }
    
    public static func resetIncorrectPasswordCount() {
        UserDefaultsUtil.setInt(key: .incorrectPasswordCount, value: 0)
    }
    
    // MARK: Lock Code
    
    static func getLockCode() -> String {
        return UserDefaultsUtil.getString(key: .lockCode)
    }
    
    static func setLockCode(newLockCode: String) {
        UserDefaultsUtil.setString(key: .lockCode, value: newLockCode)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setString(key: .lockCode, value: newLockCode)
        }
    }
    
    // MARK: Lock Delay
    
    static func getLockDelay() -> LockDelay {
        return UserDefaultsUtil.getEnum(key: .lockDelay, defaultValue: .defaultValue)
    }
    
    static func setLockDelay(_ newLockDelay: LockDelay) {
        setEnum(key: .lockDelay, value: newLockDelay)
    }
    
    // MARK: Lock Type
    
    static func getLockType() -> LockType {
        return UserDefaultsUtil.getEnum(key: .lockType, defaultValue: .defaultValue)
    }
    
    static func setLockType(_ newLockType: LockType) {
        setEnum(key: .lockType, value: newLockType)
        
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        
        let iconName: String?
        switch newLockType {
        case .off, .normal: iconName = nil
        case .trains: iconName = "AltAppIcon"
        }
        
        if iconName != UIApplication.shared.alternateIconName {
            UIApplication.shared.setAlternateIconName(iconName)
        }
    }
    
    // MARK: Show Account Warning
    
    static func showAccountWarning() -> Bool {
        return UserDefaultsUtil.getBool(key: .showAccountWarning, defaultValue: false)
    }
    
    static func setAccountWarning(_ newAccountWarning: Bool) {
        setBool(key: .showAccountWarning, value: newAccountWarning)
    }
    
    // MARK: Show Ads
    
    static func showAds() -> Bool {
        return UserDefaultsUtil.getBool(key: .showAds, defaultValue: true)
    }
    
    static func toggleShowAds() {
        let newShowAds = !showAds()
        setBool(key: .showAds, value: newShowAds)
        if saveToFirebase() {
            FirebaseSettingUtil.setBool(key: .showAds, value: newShowAds)
        }
    }
    
    // MARK: Analytics
    
    static func getEnableAnalytics() -> Bool {
        return UserDefaultsUtil.getBool(key: .enableAnalytics, defaultValue: true)
    }
    
    static func toggleEnableAnalytics() {
        let newEnableAnalytics = !getEnableAnalytics()
        setBool(key: .enableAnalytics, value: newEnableAnalytics)
        
        Analytics.setAnalyticsCollectionEnabled(SettingsManager.getEnableAnalytics())
        
        if saveToFirebase() {
            FirebaseSettingUtil.setBool(key: .enableAnalytics, value: newEnableAnalytics)
        }
    }
    
    // MARK: Crash Reports
    
    static func getEnableCrashReports() -> Bool {
        return UserDefaultsUtil.getBool(key: .enableCrashReports, defaultValue: true)
    }
    
    static func toggleEnableCrashReports() {
        let newEnableCrashReports = !getEnableCrashReports()
        setBool(key: .enableCrashReports, value: newEnableCrashReports)
        
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(SettingsManager.getEnableCrashReports())
        
        if saveToFirebase() {
            FirebaseSettingUtil.setBool(key: .enableCrashReports, value: newEnableCrashReports)
        }
    }
    
    // MARK: Show Welcome
    
    static func showWelcome() -> Bool {
        return UserDefaultsUtil.getBool(key: .showWelcome, defaultValue: true)
    }
    
    static func setShowWelcome(_ newShowWelcome: Bool) {
        setBool(key: .showWelcome, value: newShowWelcome)
    }
    
    // MARK: Start Date
    
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
    
    // MARK: Theme
    
    static func getTheme() -> Theme {
        return UserDefaultsUtil.getEnum(key: .theme, defaultValue: .pink)
    }
    
    static func setTheme(_ newTheme: Theme) {
        setEnum(key: .theme, value: newTheme)
    }
    
    // MARK: User Last Seen
    
    public static func getUserLastSeen() -> Date {
        return UserDefaultsUtil.getDate(.userLastSeen) ?? Date()
    }
    
    public static func updateUserLastSeen() {
        UserDefaultsUtil.setDate(key: .userLastSeen, value: Date())
    }
    
    // MARK: JSON Importing/Exporting
    public static func getSettingsForJson() -> JsonSettings {
        return JsonSettings(
                currentiOSVersion: getCurrentiOSVersion(),
                startDate: getStartDate().toEpochDay(),
                theme: getTheme().rawValue)
    }
    
    public static func importSettingsFromJson(_ settings: JsonSettings) {
        if let startDateInt = settings.startDate {
            setStartDate(Date.ofEpochDay(startDateInt))
        }
        if let themeString = settings.theme, let theme = Theme.init(rawValue: themeString) {
            setTheme(theme)
        }
    }
    
    // MARK: Helpers
    
    private static func setBool(key: SettingsManager.Key, value: Bool) {
        UserDefaultsUtil.setBool(key: key, value: value)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setBool(key: key, value: value)
        }
    }
    
    private static func setEnum<T>(key: SettingsManager.Key, value: T) where T: RawRepresentable, T.RawValue == String {
        UserDefaultsUtil.setEnum(key: key, value: value)
        
        if saveToFirebase() {
            FirebaseSettingUtil.setEnum(key: key, value: value)
        }
    }
    
    // MARK: Firebase handling
    
    static func enableFirebaseSync() {
        UserDefaultsUtil.setBool(key: .saveToFirebase, value: true)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.firebaseSettingUtil.addListener()
    }
    
    static func disableFirebaseSync() {
        UserDefaultsUtil.setBool(key: .saveToFirebase, value: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.firebaseSettingUtil.removeListener()
    }
    
    static func firebaseNeedsSetup() {
        disableFirebaseSync()
        
        if Auth.auth().currentUser != nil {
            attemptFirebaseAutoSetup()
        }
    }
    
    static func attemptFirebaseAutoSetup() {
        do {
            let docRef = try FirebaseSettingUtil.getSettingsDocRef()
            
            docRef.getDocument { (document, _) in
                if let document = document, document.exists, let data = document.data() {
                    var differences = [(Key, Any)]()
                    
                    Key.allCases.forEach { key in
                        if let value = data[key.rawValue] {
                            let isDifferent: Bool
                            
                            switch key {
                            case .lockCode: isDifferent = value is String && value as! String != getLockCode()
                            case .lockDelay: isDifferent = value is String && LockDelay(rawValue: value as! String) != nil && value as! String != getLockDelay().rawValue
                            case .lockType: isDifferent = value is String && LockType(rawValue: value as! String) != nil && value as! String != getLockType().rawValue
                            case .startDate: isDifferent = value is Int && value as! Int != getStartDate().toEpochDay()
                            case .theme: isDifferent = value is String && Theme(rawValue: value as! String) != nil && value as! String != getTheme().rawValue
                            case .showAds: isDifferent = value is Bool && value as! Bool != showAds()
                            case .enableAnalytics: isDifferent = value is Bool && value as! Bool != getEnableAnalytics()
                            case .enableCrashReports: isDifferent = value is Bool && value as! Bool != getEnableCrashReports()
                            
                            case .currentiOSVersion, .incorrectPasswordCount, .saveToFirebase, .showAccountWarning, .showWelcome, .userLastSeen: isDifferent = false
                            }
                            
                            if isDifferent {
                                differences.append((key, value))
                            }
                        } else if let value = firebaseValueForKey(key) {
                            docRef.updateData([key.rawValue: value])
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
    
    static func firebaseValueForKey(_ key: Key) -> Any? {
        switch key {
        case .lockCode: return getLockCode()
        case .lockDelay: return getLockDelay().rawValue
        case .lockType: return getLockType().rawValue
        case .showAds: return showAds()
        case .showWelcome: return showWelcome()
        case .startDate: return getStartDate().toEpochDay()
        case .theme: return getTheme().rawValue
        case .enableAnalytics: return getEnableAnalytics()
        case .enableCrashReports: return getEnableCrashReports()
        case .showAds: return showAds()
        case .currentiOSVersion, .incorrectPasswordCount, .saveToFirebase, .showAccountWarning, .userLastSeen: return nil
        }
    }
    
    static func saveToFirebase() -> Bool {
        return UserDefaultsUtil.getBool(key: .saveToFirebase, defaultValue: false)
    }
    
    enum Key: String, CaseIterable {
        case currentiOSVersion
        case incorrectPasswordCount
        case lockCode
        case lockDelay
        case lockType
        case saveToFirebase
        case showAccountWarning
        case showAds
        case showWelcome
        case startDate
        case theme
        case userLastSeen
        case enableAnalytics
        case enableCrashReports
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
        return LockType.allCases.map { theme in
            theme.getDisplayName()
        }
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
        return LockDelay.allCases.map { theme in
            theme.getDisplayName()
        }
    }
    
    func getIndex() -> Int {
        return LockDelay.allCases.firstIndex(of: self)!
    }
}

enum SettingsError: Error {
    case documentDoesNotExist
    case userNotLoggedIn
}

struct JsonSettings: Codable {
    let currentiOSVersion: Int?
    let startDate: Int?
    let theme: String?
}
