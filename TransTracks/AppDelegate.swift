//
//  AppDelegate.swift
//  TransTracks
//
//  Created by Cassie Wilson on 6/11/18.
//  Copyright © 2018-2021 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import FirebaseCrashlytics
import Firebase
import FirebaseUI
import GoogleMobileAds
import UIKit
import ZIPFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: Constants
    
    private static let TAG_BLOCKING_VIEW = 98734
    
    //MARK: Properties
    
    var window: UIWindow?
    
    var dataController: DataController!
    var domainManager: DomainManager!
    
    lazy var firebaseSettingUtil: FirebaseSettingUtil = FirebaseSettingUtil()
    
    //MARK: Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        #if PRODUCTION
        Analytics.setAnalyticsCollectionEnabled(true)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        dataController = DataController(modelName: "TransTracks")
        domainManager = DomainManager(dataController: dataController)
        
        appVersionUpdateIfNecessary()
        
        let rootController = window!.rootViewController
        let homeViewController: HomeViewController
        
        if let navigationController = rootController as? UINavigationController {
            homeViewController = navigationController.topViewController as! HomeViewController
            
            if let lockController = getLockControllerToShow() {
                navigationController.pushViewController(lockController, animated: false)
            }
        } else {
            fatalError("Error setting up app")
        }
        
        homeViewController.domainManager = domainManager
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        } else if handleImportingBackup(url) {
            return true
        }
        
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        SettingsManager.updateUserLastSeen()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        let rootController = window!.rootViewController
        if let navigationController = rootController as? UINavigationController {
            lockAppIfRequired(navigationController)
            
            addBlockingViewIfRequired(navigationController)
        } else {
            fatalError("Error locking app")
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        removeBlockingView()
        
        let rootController = window!.rootViewController
        if let navigationController = rootController as? UINavigationController {
            lockAppIfRequired(navigationController)
        } else {
            fatalError("Error locking app")
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        SettingsManager.resetIncorrectPasswordCount()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        try? self.dataController.viewContext.save()
    }
    
    //MARK: Handle importing backup
    func handleImportingBackup(_ url: URL) -> Bool {
        if url.lastPathComponent.hasSuffix(".ttbackup") {
            let alert = UIAlertController(
                    title: NSLocalizedString("importWarningTitle", comment: ""),
                    message: NSLocalizedString("importWarningMessage", comment: ""),
                    preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default) { [weak self] action in
                guard let self = self else { return }
                self.importBackup(url)
            })
            alert.show()
            
            return true
        }
        
        return false
    }
    
    //MARK: Helpers
    
    private func addBlockingViewIfRequired(_ navigationController: UINavigationController) {
        guard SettingsManager.getLockType() != LockType.off else { return }
        guard !isLockTopView(navigationController) else { return }
        guard window!.viewWithTag(AppDelegate.TAG_BLOCKING_VIEW) == nil else { return }
        
        let blockingView = UIView(frame: window!.frame)
        blockingView.backgroundColor = UIColor.white
        blockingView.tag = AppDelegate.TAG_BLOCKING_VIEW
        window!.addSubview(blockingView)
    }
    
    private func removeBlockingView() {
        if let blockingView = window!.viewWithTag(AppDelegate.TAG_BLOCKING_VIEW) {
            blockingView.removeFromSuperview()
        }
    }
    
    private func importBackup(_ url: URL) {
        let loadingAlert = UIAlertController(
                title: NSLocalizedString("importingBackupFile", comment: ""), message: nil, preferredStyle: .alert
        )
        loadingAlert.show()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let archive = Archive(url: url, accessMode: .read) else {
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true)
                        
                        AlertHelper.showMessage(
                                title: NSLocalizedString("error", comment: ""),
                                message: NSLocalizedString("importError", comment: "")
                        )
                    }
                    return
                }
                
                var photoIssues = 0
                var milestoneIssues = 0
                
                for entry in archive.makeIterator() {
                    switch entry.type {
                    
                    case .file:
                        if entry.path.contains("data.json") {
                            let _ = try archive.extract(entry) { data in
                                let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                                for (key, value) in json {
                                    switch key {
                                    case "settings":
                                        let valueData = try JSONSerialization.data(withJSONObject: value)
                                        let jsonSettings = try JSONDecoder().decode(JsonSettings.self, from: valueData)
                                        SettingsManager.importSettingsFromJson(jsonSettings)
                                        break
                                    case "photos":
                                        guard let value = value as? [[String: Any]] else { continue }
                                        for photo in value {
                                            do {
                                                let _ = try Photo.fromJson(json: photo, context: self.dataController.backgroundContext)
                                            } catch {
                                                print(error)
                                                photoIssues += 1
                                            }
                                        }
                                        break
                                    case "milestones":
                                        guard let value = value as? [[String: Any]] else { continue }
                                        for milestone in value {
                                            do {
                                                let _ = try Milestone.fromJson(json: milestone, context: self.dataController.backgroundContext)
                                            } catch {
                                                print(error)
                                                milestoneIssues += 1
                                            }
                                        }
                                        break
                                    default:
                                        break //Skip keys we don't handle
                                    }
                                }
                                
                                try self.dataController.backgroundContext.save()
                            }
                        } else if entry.path.contains("photos") {
                            if let entryPathUrl = URL(string: entry.path) {
                                do {
                                    let photoUrl = try FileUtil.getPhotoDirectory().appendingPathComponent(entryPathUrl.lastPathComponent)
                                    try? FileManager.default.removeItem(at: photoUrl)
                                    let _ = try archive.extract(entry, to: photoUrl)
                                } catch {
                                    print(error)
                                    photoIssues += 1
                                }
                            }
                        }
                    case .directory, .symlink:
                        break; //Don't need to handle directories or symlinks
                    }
                }
                
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self.window?.rootViewController?.loadView()
                        if photoIssues > 0 || milestoneIssues > 0 {
                            var errors = ""
                            if (photoIssues > 0) {
                                let format = NSLocalizedString("photos", comment: "")
                                errors += String.localizedStringWithFormat(format, photoIssues)
                            }
                            if (milestoneIssues > 0) {
                                if errors.isNotEmpty {
                                    errors += "\n"
                                }
                                let format = NSLocalizedString("milestones", comment: "")
                                errors += String.localizedStringWithFormat(format, milestoneIssues)
                            }
                            let messageFormat = NSLocalizedString("importPartialSuccessDescription", comment: "")
                            let message = String.localizedStringWithFormat(messageFormat, errors)
                            
                            AlertHelper.showMessage(
                                    title: NSLocalizedString("importPartialSuccessTitle", comment: ""),
                                    message: message
                            )
                        } else {
                            AlertHelper.showMessage(title: NSLocalizedString("importCompleteSuccess", comment: ""))
                        }
                        
                        self.window?.rootViewController?.loadView()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        AlertHelper.showMessage(
                                title: NSLocalizedString("error", comment: ""),
                                message: NSLocalizedString("importFailure", comment: "")
                        )
                    }
                }
                print(error)
            }
        }
    }
    
    private func isLockTopView(_ navigationController: UINavigationController) -> Bool {
        return navigationController.topViewController is NormalLockController || navigationController.topViewController is TrainLockController
    }
    
    private func lockAppIfRequired(_ navigationController: UINavigationController) {
        guard !isLockTopView(navigationController) else { return }
        
        var shouldShow = false
        
        let lastSeen = SettingsManager.getUserLastSeen()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: lastSeen, to: Date())
        
        switch SettingsManager.getLockDelay() {
        case .instant: shouldShow = true
        case .oneMinute: shouldShow = components.minute ?? 0 >= 1
        case .twoMinutes: shouldShow = components.minute ?? 0 >= 2
        case .fiveMinutes: shouldShow = components.minute ?? 0 >= 5
        case .fifteenMinutes: shouldShow = components.minute ?? 0 >= 15
        }
        
        if shouldShow, let lock = getLockControllerToShow() {
            navigationController.pushViewController(lock, animated: false)
        }
    }
    
    private func getLockControllerToShow() -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch SettingsManager.getLockType() {
        case .normal: return storyboard.instantiateViewController(withIdentifier: "NormalLock")
        case .trains: return storyboard.instantiateViewController(withIdentifier: "TrainLock")
        default: return nil
        }
    }
    
    func showSettingsConflictDialog(_ differences: [(SettingsManager.Key, Any)]) {
        if let navigationController = window!.rootViewController as? UINavigationController {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let settingsConflictVC = storyboard.instantiateViewController(withIdentifier: "SettingsConflict") as! SettingsConflictController
            settingsConflictVC.modalPresentationStyle = .overFullScreen
            settingsConflictVC.differences = differences
            
            navigationController.present(settingsConflictVC, animated: true, completion: nil)
        } else {
            fatalError("Error setting up app")
        }
    }
    
    func appVersionUpdateIfNecessary() {
        let currentVersion = SettingsManager.getCurrentiOSVersion()
        let newVersion = Int(Bundle.main.buildVersionNumber!)!
        
        guard currentVersion != newVersion else { return }
        
        if currentVersion == nil {
            //User's first tracked version
            
            //Untracked user that has a lock at this point, we should warn them about not having an account
            if SettingsManager.getLockType() != .off {
                Analytics.logEvent("user_needs_to_show_warning", parameters: nil)
                SettingsManager.setAccountWarning(true)
            }
        } else if let currentVersion = currentVersion {
            if currentVersion <= 14 {
                //Fix milestones not having UUIDs set when they were created
                let milestonesRequest: NSFetchRequest<Milestone> = Milestone.fetchRequest()
                if let milestones = try? dataController.backgroundContext.fetch(milestonesRequest) {
                    for milestone in milestones {
                        if milestone.id == nil {
                            milestone.id = UUID()
                        }
                    }
                    
                    try? domainManager.dataController.backgroundContext.save()
                }
            }
        }
        
        SettingsManager.updateCurrentiOSVersion()
    }
}
