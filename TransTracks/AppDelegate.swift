//
//  AppDelegate.swift
//  TransTracks
//
//  Created by Cassie Wilson on 6/11/18.
//  Copyright © 2018 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Crashlytics
import Fabric
import Firebase
import FirebaseUI
import GoogleMobileAds
import TwitterKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: Constants
    
    private static let TAG_BLOCKING_VIEW = 98734
    
    //MARK: Properties
    
    var window: UIWindow?
    
    var dataController:DataController!
    var domainManager: DomainManager!
    
    //MARK: Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        #if DEBUG
            AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(false)
        #else
            Fabric.with([Crashlytics()])
        #endif
        
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let googleServiceInfo = NSDictionary(contentsOfFile: path),
           let adMobAppId = googleServiceInfo["ADMOB_APP_ID"] as? String {
            GADMobileAds.configure(withApplicationID: adMobAppId)
        }
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let twitter = config["twitter"] as? NSDictionary,
           let consumerKey = twitter["consumerKey"] as? String,
           let consumerSecret = twitter["consumerSecret"] as? String {
            TWTRTwitter.sharedInstance().start(withConsumerKey: consumerKey, consumerSecret: consumerSecret)
        }
        
        dataController = DataController(modelName: "TransTracks")
        domainManager = DomainManager(dataController: dataController)
        
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
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        } else if TWTRTwitter.sharedInstance().application(app, open: url, options: options) {
            return true
        }
        
        return false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        UserDefaultsUtil.updateUserLastSeen()
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
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        try? self.dataController.viewContext.save()
    }
    
    //MARK: Helpers
    
    private func addBlockingViewIfRequired(_ navigationController : UINavigationController){
        guard UserDefaultsUtil.getLockType() != LockType.off else { return }
        guard !isLockTopView(navigationController) else { return }
        guard window!.viewWithTag(AppDelegate.TAG_BLOCKING_VIEW) == nil else { return }
        
        let blockingView = UIView(frame: window!.frame)
        blockingView.backgroundColor = UIColor.white
        blockingView.tag = AppDelegate.TAG_BLOCKING_VIEW
        window!.addSubview(blockingView)
    }
    
    private func removeBlockingView(){
        if let blockingView = window!.viewWithTag(AppDelegate.TAG_BLOCKING_VIEW) {
            blockingView.removeFromSuperview()
        }
    }
    
    private func isLockTopView(_ navigationController: UINavigationController) -> Bool {
        return navigationController.topViewController is NormalLockController || navigationController.topViewController is TrainLockController
    }
    
    private func lockAppIfRequired(_ navigationController: UINavigationController){
        guard !isLockTopView(navigationController) else { return }
        
        var shouldShow = false
        
        let lastSeen = UserDefaultsUtil.getUserLastSeen()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute], from: lastSeen, to: Date())
        
        switch UserDefaultsUtil.getLockDelay() {
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

        switch UserDefaultsUtil.getLockType() {
        case .normal: return storyboard.instantiateViewController(withIdentifier: "NormalLock")
        case .trains: return storyboard.instantiateViewController(withIdentifier: "TrainLock")
        default: return nil
        }
    }
}
