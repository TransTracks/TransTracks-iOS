//
//  FirebaseSettingUtil.swift
//  TransTracks
//
//  Created by Cassie Wilson on 30/7/19.
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
import Foundation

class FirebaseSettingUtil {
    private let db = Firestore.firestore()
    
    private var listener: ListenerRegistration?
    
    func addListener() {
        removeListener()
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        listener = db.collection(user.uid).document(FirebaseSettingUtil.SETTINGS_DOCUMENT).addSnapshotListener { snapshot, error in
            if let error = error {
                print(error)
            }
            
            if let snapshot = snapshot, let data = snapshot.data(){
                data.forEach{ key, value in
                    if let key = SettingsManager.Key(rawValue: key){
                        switch key {
                        case .lockCode:
                            if value is String {
                                UserDefaultsUtil.setString(key: key, value: value as! String)
                            } else {
                                print("\(key.rawValue) is not a String : '\(value)'")
                            }
                            
                        case .lockDelay:
                            if value is String, let delay = LockDelay(rawValue: value as! String){
                                UserDefaultsUtil.setEnum(key: key, value: delay)
                            } else {
                                print("\(key.rawValue) is not a String : '\(value)'")
                            }
                            
                        case .lockType:
                            if value is String, let type = LockType(rawValue: value as! String){
                                UserDefaultsUtil.setEnum(key: key, value: type)
                            } else {
                                print("\(key.rawValue) is not a String : '\(value)'")
                            }
                            
                        case .showAds, .showWelcome:
                            if value is Bool {
                                UserDefaultsUtil.setBool(key: key, value: value as! Bool)
                            } else {
                                print("\(key.rawValue) is not a Bool : '\(value)'")
                            }
                            
                        case .startDate:
                            if value is Int {
                                UserDefaultsUtil.setDate(key: key, value: Date.ofEpochDay(value as! Int))
                            } else {
                                print("\(key.rawValue) is not a Int : '\(value)'")
                            }
                            
                        case .theme:
                            if value is String, let theme = Theme(rawValue: value as! String){
                                UserDefaultsUtil.setEnum(key: key, value: theme)
                            } else {
                                print("\(key.rawValue) is not a String : '\(value)'")
                            }
                            
                        //Don't need to sync .saveToFirebase, .userLastSeen
                        case .currentiOSVersion, .saveToFirebase, .userLastSeen:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }
    }
    
    func removeListener(){
        listener?.remove()
        listener = nil
    }
    
    //MARK: Static helpers
    
    private static let SETTINGS_DOCUMENT = "settings"
    
    static let errorHandling: (Error?) -> Void = { error in
        if let error = error as NSError? {
            print(error)
            
            if error.code == FirestoreErrorCode.notFound.rawValue {
                SettingsManager.firebaseNeedsSetup()
            }
        }
    }
    
    static func setBool(key: SettingsManager.Key, value: Bool) {
        do {
            let doc = try getSettingsDocRef()
            
            doc.updateData([key.rawValue : value], completion: errorHandling)
        } catch {
            print(error)
        }
    }
    
    static func setEnum<T>(key: SettingsManager.Key, value: T) where T : RawRepresentable, T.RawValue == String {
        do {
            let doc = try getSettingsDocRef()
            
            doc.updateData([key.rawValue : value.rawValue], completion: errorHandling)
        } catch {
            print(error)
        }
    }
    
    static func setInt(key: SettingsManager.Key, value: Int) {
        do {
            let doc = try getSettingsDocRef()
            
            doc.updateData([key.rawValue : value], completion: errorHandling)
        } catch {
            print(error)
        }
    }
    
    static func setString(key: SettingsManager.Key, value: String) {
        do {
            let doc = try getSettingsDocRef()
            
            doc.updateData([key.rawValue : value], completion: errorHandling)
        } catch {
            print(error)
        }
    }
    
    static func getSettingsDocRef() throws -> DocumentReference {
        guard let user = Auth.auth().currentUser else {
            throw SettingsError.userNotLoggedIn
        }
        
        return Firestore.firestore().collection(user.uid).document(SETTINGS_DOCUMENT)
    }
}
