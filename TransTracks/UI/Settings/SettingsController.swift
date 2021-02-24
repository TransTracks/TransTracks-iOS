//
//  SettingsController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 18/2/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import Firebase
import FirebaseAuth
import FirebaseUI
import PasswordTextField
import Toast_Swift
import UIKit
import ZIPFoundation

class SettingsController: BackgroundGradientViewController {
    
    //MARK: Properties
    private var tempName: String?
    private var tempEmail: String?
    private var tempTheme: Theme?
    private var tempLockType: LockType?
    private var tempPassword: String?
    private var confirmPassword: String?
    private var tempLockDelay: LockDelay?
    
    private var tempTextFieldAction: TextFieldReturnAction?
    
    private let privacyPolicyURL = URL(string: "http://www.drspaceboo.com/privacy-policy/")!
    private let termsOfServiceURL = URL(string: "http://www.drspaceboo.com/terms-of-service/")!
    
    var dataController: DataController!
    
    var showAuthOnAppear: Bool = false
    
    //MARK: Outlets
    
    @IBOutlet var adViewHolder: AdContainerView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adViewHolder.setupAd("ca-app-pub-4389848400124499/9443250102", rootViewController: self)
        
        navigationItem.titleView?.tintColor = UIColor.white
        copyrightLabel.text = String(format: NSLocalizedString("copyrightWithCurrentYear", comment: ""), Date.getCurrentYear())
        
        loadingIndicator.stopAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if showAuthOnAppear {
            showAuth()
        }
    }
    
    //MARK: Helper function
    func showAuth() {
        //Sign in
        if let authUI = FUIAuth.defaultAuthUI() {
            authUI.privacyPolicyURL = privacyPolicyURL
            authUI.tosurl = termsOfServiceURL
            
            var providers: [FUIAuthProvider] = [FUIEmailAuth(), FUIGoogleAuth(), FUIOAuth.twitterAuthProvider()]
            if #available(iOS 13, *) {
                providers.append(FUIOAuth.appleAuthProvider())
            }
            
            authUI.providers = providers
            authUI.delegate = self
            present(authUI.authViewController(), animated: true, completion: nil)
        }
    }
    
    private func showRelogInDialog() {
        let alert = UIAlertController(title: NSLocalizedString("sessionExpiredTitle", comment: ""), message: NSLocalizedString("sessionExpiredMessage", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("later", comment: ""), style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
            self.showAuth()
        }))
        alert.show()
    }
    
    //MARK: Button handling
    
    @objc func accountNameClick(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        self.tempName = currentUser.displayName
        
        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = NSLocalizedString("enterAccountName", comment: "")
            textField.backgroundColor = nil
            textField.keyboardAppearance = .default
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = nil
            textField.keyboardType = .default
            textField.isSecureTextEntry = false
            textField.returnKeyType = .done
            textField.text = currentUser.displayName
            textField.action { textField in
                self.tempName = textField.text
            }
        }
        
        let alert = UIAlertController(title: NSLocalizedString("updateAccountName", comment: ""), message: nil, preferredStyle: .alert)
        alert.addOneTextField(configuration: config)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("update", comment: ""), style: .default, handler: { action in
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = self.tempName
            changeRequest.commitChanges { error in
                self.tableView.reloadRows(at: [IndexPath(row: Row.account.rawValue, section: 0)], with: .automatic)
                
                if let error = error {
                    let code = (error as NSError).code
                    if code == AuthErrorCode.userTokenExpired.rawValue || code == AuthErrorCode.userNotFound.rawValue {
                        self.showRelogInDialog()
                    }
                    
                    print(error.localizedDescription)
                    self.view.makeToast(NSLocalizedString("unableToUpdateName", comment: ""))
                }
            }
        }))
        
        alert.show()
    }
    
    @objc func accountEmailClick(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        self.tempEmail = currentUser.email
        
        let updateAction = UIAlertAction(title: NSLocalizedString("update", comment: ""), style: .default, handler: { action in
            guard let email = self.tempEmail, email.simpleIsEmail() else { return }
            
            currentUser.updateEmail(to: email) { error in
                self.tableView.reloadRows(at: [IndexPath(row: Row.account.rawValue, section: 0)], with: .automatic)
                
                if let error = error {
                    let code = (error as NSError).code
                    
                    var toastMessage = NSLocalizedString("unableToUpdateEmail", comment: "")
                    
                    switch code {
                    case AuthErrorCode.userTokenExpired.rawValue,
                         AuthErrorCode.userNotFound.rawValue,
                         AuthErrorCode.requiresRecentLogin.rawValue:
                        self.showRelogInDialog()
                    
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        toastMessage = NSLocalizedString("emailInUse", comment: "")
                    
                    case AuthErrorCode.invalidEmail.rawValue:
                        toastMessage = NSLocalizedString("emailInvalid", comment: "")
                    
                    default:
                        break;
                    }
                    
                    print(error.localizedDescription)
                    self.view.makeToast(toastMessage)
                }
            }
        })
        updateAction.isEnabled = false
        
        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = NSLocalizedString("enterEmailAddress", comment: "")
            textField.backgroundColor = nil
            textField.keyboardAppearance = .default
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = nil
            textField.keyboardType = .emailAddress
            textField.isSecureTextEntry = false
            textField.returnKeyType = .done
            textField.text = currentUser.email
            textField.action { textField in
                self.tempEmail = textField.text
                updateAction.isEnabled = self.tempEmail?.simpleIsEmail() ?? false
            }
        }
        
        let alert = UIAlertController(title: NSLocalizedString("updateEmailAddress", comment: ""), message: nil, preferredStyle: .alert)
        alert.addOneTextField(configuration: config)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(updateAction)
        
        alert.show()
    }
    
    @objc func primaryActionClick(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            showAuth()
        } else {
            //Change password flow
            if let email = Auth.auth().currentUser?.email {
                Auth.auth().sendPasswordReset(withEmail: email, completion: { error in
                    if let error = error {
                        print(error)
                        self.view.makeToast(NSLocalizedString("passwordResetFailed", comment: ""))
                    } else {
                        self.view.makeToast(NSLocalizedString("passwordResetSuccess", comment: ""))
                    }
                })
            } else {
                view.makeToast(NSLocalizedString("unableToResetPassword", comment: ""))
            }
        }
    }
    
    @objc func signOut(_ sender: Any) {
        guard Auth.auth().currentUser != nil else { return }
        
        if let authUI = FUIAuth.defaultAuthUI() {
            do {
                try authUI.signOut()
                SettingsManager.disableFirebaseSync()
                tableView.reloadRows(at: [IndexPath(row: Row.account.rawValue, section: 0)], with: .automatic)
            } catch {
                print(error)
                view.makeToast(NSLocalizedString("signOutError", comment: ""))
            }
        } else {
            view.makeToast(NSLocalizedString("signOutError", comment: ""))
        }
    }
    
    @objc func importData(_ sender: Any) {
        let importMenu: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            importMenu = UIDocumentPickerViewController(forOpeningContentTypes: [.init(importedAs: "com.drspaceboo.transtracks.ttbackup", conformingTo: .zip)])
        } else {
            importMenu = UIDocumentPickerViewController(documentTypes: ["com.drspaceboo.transtracks.ttbackup"], in: .import)
        }
        importMenu.delegate = self
        present(importMenu, animated: true)
    }
    
    @objc func exportData(_ sender: Any) {
        loadingIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                //Exporting Data file
                var jsonDictionary = [String: Any]()
                jsonDictionary["settings"] = try JSONSerialization.jsonObject(
                        with: try JSONEncoder().encode(SettingsManager.getSettingsForJson()), options: []
                )
                
                let photosRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                let photos = try self.dataController.backgroundContext.fetch(photosRequest)
                jsonDictionary["photos"] = try JSONSerialization.jsonObject(
                        with: try JSONEncoder().encode(photos), options: []
                )
                
                let milestonesRequest: NSFetchRequest<Milestone> = Milestone.fetchRequest()
                let milestones = try self.dataController.backgroundContext.fetch(milestonesRequest)
                jsonDictionary["milestones"] = try JSONSerialization.jsonObject(
                        with: try JSONEncoder().encode(milestones), options: []
                )
                
                let tempDataFileUrl = try FileUtil.getNewTempFileURL(fileName: "data.json")
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: .prettyPrinted)
                try jsonData.write(to: tempDataFileUrl)
                
                //Create zip file
                let timeStamp = FileUtil.timestampFormatter().string(from: Date())
                let tempZipUrl = try FileUtil.getNewTempFileURL(fileName: "\(timeStamp).ttbackup")
                
                guard let archive = Archive(url: tempZipUrl, accessMode: .create) else {
                    self.stopLoading()
                    AlertHelper.showMessage(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("exportFailure", comment: ""))
                    return
                }
                
                try archive.addEntry(
                        with: tempDataFileUrl.lastPathComponent,
                        relativeTo: tempDataFileUrl.deletingLastPathComponent(),
                        compressionMethod: .deflate
                )
                try archive.addDirectoryRecursively(try FileUtil.getPhotoDirectory(), compressionMethod: .deflate)
                
                //Sharing the resulting zip
                let activityViewController = UIActivityViewController(activityItems: [tempZipUrl], applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: nil)
            } catch {
                self.stopLoading()
                AlertHelper.showMessage(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("exportFailure", comment: ""))
                print(error)
            }
            
            self.stopLoading()
        }
    }
    
    //MARK: Helper functions
    private func stopLoading() {
        DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
    }
}

extension SettingsController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row(rawValue: indexPath.row)!
        let rowType = row.getRowType()
        let cell = dequeueCell(tableView, rowType)
        
        switch rowType {
        case .account: configAccountRow(cell as! AccountCell, row)
        case .setting: configSettingRow(cell as! SettingCell, row)
        case .divider: break //Divider cells don't need configuring
        case .button: configButtonRow(cell as! ButtonCell, row)
        case .doubleButton: configDoubleButtonRow(cell as! DoubleButtonCell, row)
        }
        
        //Styling the selected background
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
    private func dequeueCell(_ tableView: UITableView, _ rowType: RowType) -> UITableViewCell {
        let identifier: String
        
        switch rowType {
        case .account: identifier = "AccountCell"
        case .setting: identifier = "SettingCell"
        case .divider: identifier = "Divider"
        case .button: identifier = "ButtonCell"
        case .doubleButton: identifier = "DoubleButtonCell"
        }
        
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = Row(rawValue: indexPath.row)!.getRowType()
        
        switch rowType {
        case .account:
            if Auth.auth().currentUser == nil {
                return 130
            } else {
                return 160
            }
        case .setting, .button, .doubleButton: return 50
        case .divider: return 2
        }
    }
    
    private func configAccountRow(_ cell: AccountCell, _ row: Row) {
        let userLoggedIn: Bool
        let primaryActionText: String
        var hidePrimaryAction: Bool = false
        
        if let user = Auth.auth().currentUser {
            userLoggedIn = true
            
            if user.email != nil {
                if user.hasPasswordProvider() {
                    primaryActionText = NSLocalizedString("changePassword", comment: "")
                } else {
                    primaryActionText = NSLocalizedString("setPassword", comment: "")
                }
            } else {
                hidePrimaryAction = true
                primaryActionText = ""
            }
            
            cell.userNameLabel.text = user.displayName ?? NSLocalizedString("unknown", comment: "")
            cell.userEmailLabel.text = user.email ?? NSLocalizedString("unknown", comment: "")
        } else {
            userLoggedIn = false
            primaryActionText = NSLocalizedString("signIn", comment: "")
        }
        
        cell.infoLabel.isHidden = userLoggedIn
        cell.nameViews.isHidden = !userLoggedIn
        cell.emailViews.isHidden = !userLoggedIn
        cell.signOutButton.isHidden = !userLoggedIn
        
        cell.primaryActionButton.isHidden = hidePrimaryAction
        
        cell.primaryActionButton.setTitle(primaryActionText, for: .normal)
        
        cell.nameViews.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(accountNameClick(_:))))
        cell.emailViews.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(accountEmailClick(_:))))
        cell.primaryActionButton.addTarget(self, action: #selector(primaryActionClick(_:)), for: .touchUpInside)
        cell.signOutButton.addTarget(self, action: #selector(signOut(_:)), for: .touchUpInside)
    }
    
    private func configSettingRow(_ cell: SettingCell, _ row: Row) {
        let title: String
        let value: String
        var description: String?
        
        var rowEnabled = true
        
        switch row {
        case .startDate:
            title = NSLocalizedString("startDateLabel", comment: "")
            value = SettingsManager.getStartDate().toFullDateString()
        
        case .theme:
            title = NSLocalizedString("themeLabel", comment: "")
            value = SettingsManager.getTheme().getDisplayName()
        
        case .lockMode:
            title = NSLocalizedString("lockModeLabel", comment: "")
            value = SettingsManager.getLockType().getDisplayName()
            description = NSLocalizedString("lockModeDescription", comment: "")
        
        case .lockDelay:
            title = NSLocalizedString("lockDelayLabel", comment: "")
            value = SettingsManager.getLockDelay().getDisplayName()
            
            rowEnabled = SettingsManager.getLockType() != LockType.off
        
        case .appVersion:
            title = NSLocalizedString("appVersionLabel", comment: "")
            
            let versionName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?.?.?"
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            
            value = String(format: "%@ (%@)", arguments: [versionName, buildNumber])
        
        default:
            fatalError("This row hasn't been configured")
        }
        
        cell.titleLabel.text = title
        cell.valueLabel.text = value
        cell.descriptionLabel.text = description
        
        cell.titleLabel.isEnabled = rowEnabled
        cell.valueLabel.isEnabled = rowEnabled
        cell.descriptionLabel.isEnabled = rowEnabled
    }
    
    private func configButtonRow(_ cell: ButtonCell, _ row: Row) {
        let title: String
        
        switch row {
        case .privacyPolicy:
            title = NSLocalizedString("privacyPolicy", comment: "")
        case .termsOfService:
            title = NSLocalizedString("termsOfService", comment: "")
        
        default:
            fatalError("This row hasn't been configured")
        }
        
        cell.titleLabel.text = title
    }
    
    private func configDoubleButtonRow(_ cell: DoubleButtonCell, _ row: Row) {
        let label: String
        let firstButton: String
        let secondButton: String
        
        switch row {
        case .data:
            label = NSLocalizedString("data", comment: "")
            firstButton = NSLocalizedString("import", comment: "")
            secondButton = NSLocalizedString("export", comment: "")
            cell.firstButton.addTarget(self, action: #selector(importData(_:)), for: .touchUpInside)
            cell.secondButton.addTarget(self, action: #selector(exportData(_:)), for: .touchUpInside)
        
        default:
            fatalError("This row hasn't been configured")
        }
        
        cell.label.text = label
        cell.firstButton.titleLabel?.text = firstButton
        cell.secondButton.titleLabel?.text = secondButton
    }
    
    enum Row: Int, CaseIterable {
        case account
        case divider1
        case startDate
        case theme
        case lockMode
        case lockDelay
        case divider2
        case data
        case divider3
        case appVersion
        case privacyPolicy
        case termsOfService
        
        func getRowType() -> RowType {
            switch self {
            case .account: return .account
            case .divider1: return .divider
            case .startDate: return .setting
            case .theme: return .setting
            case .lockMode: return .setting
            case .lockDelay: return .setting
            case .divider2: return .divider
            case .data: return .doubleButton
            case .divider3: return .divider
            case .appVersion: return .setting
            case .privacyPolicy: return .button
            case .termsOfService: return .button
            }
        }
    }
    
    enum RowType {
        case setting, divider, button, account, doubleButton
    }
}

extension SettingsController: UITableViewDelegate {
    //Block selection of certain rows
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = Row(rawValue: indexPath.row)!
        
        if row == .account || // The account row can't be clicked only the button
                   row == .appVersion || // The App version cannot be clicked
                   row.getRowType() == RowType.divider || // Dividers cannot be clicked
                   (row == .lockDelay && SettingsManager.getLockType() == .off) { //If the lock type is set to OFF then the user cannot change the lock delay
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)!
        
        switch row {
        case .startDate:
            let cell = tableView.cellForRow(at: indexPath)! as! SettingCell
            let rect = getTriggerRect(cell)
            
            AlertHelper.showDatePicker(startingDate: SettingsManager.getStartDate(), maximumDate: nil, triggeringView: cell, specificTriggerRect: rect) { newDate in
                SettingsManager.setStartDate(newDate)
                tableView.reloadRows(at: [IndexPath(row: Row.startDate.rawValue, section: 0)], with: .fade)
            }
        
        case .theme:
            tempTheme = nil
            
            let alert = UIAlertController(title: NSLocalizedString("selectTheme", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addPickerView(values: [Theme.getDisplayNamesArray()], initialSelection: (column: 0, row: SettingsManager.getTheme().getIndex()), action: { _, _, index, _ in
                self.tempTheme = Theme.allCases[index.row]
                
                if let tempTheme = self.tempTheme {
                    self.setBackgroundGradient(tempTheme)
                }
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { action in
                self.setBackgroundGradient()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let newTheme = self.tempTheme {
                    SettingsManager.setTheme(newTheme)
                    tableView.reloadRows(at: [IndexPath(row: Row.theme.rawValue, section: 0)], with: .fade)
                    self.setBackgroundGradient()
                }
            }))
            
            setPopoverPresentationControllerInfo(alert, indexPath)
            alert.show()
        
        case .lockMode:
            tempLockType = nil
            tempPassword = nil
            confirmPassword = nil
            
            let alert = UIAlertController(title: NSLocalizedString("selectLockMode", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addPickerView(values: [LockType.getDisplayNamesArray()], initialSelection: (column: 0, row: SettingsManager.getLockType().getIndex()), action: { _, _, index, _ in
                self.tempLockType = LockType.allCases[index.row]
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let newLockType = self.tempLockType {
                    let currentLockType = SettingsManager.getLockType()
                    
                    if newLockType != currentLockType {
                        let hasCode = !SettingsManager.getLockCode().isEmpty
                        
                        if newLockType == .off {
                            //Turn off lock, and remove the code
                            self.showRemovePasswordAlert(indexPath)
                        } else if hasCode {
                            SettingsManager.setLockType(newLockType)
                            
                            self.tableView.reloadRows(at: [IndexPath(row: Row.lockMode.rawValue, section: 0)], with: .fade)
                        } else {
                            self.showSetPasswordAlert(indexPath)
                        }
                    }
                }
            }))
            
            setPopoverPresentationControllerInfo(alert, indexPath)
            alert.show()
        
        case .lockDelay:
            tempLockDelay = nil
            
            let alert = UIAlertController(title: NSLocalizedString("selectLockDelay", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addPickerView(values: [LockDelay.getDisplayNamesArray()], initialSelection: (column: 0, row: SettingsManager.getLockDelay().getIndex()), action: { _, _, index, _ in
                self.tempLockDelay = LockDelay.allCases[index.row]
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let tempLockDelay = self.tempLockDelay {
                    SettingsManager.setLockDelay(tempLockDelay)
                    tableView.reloadRows(at: [IndexPath(row: Row.lockDelay.rawValue, section: 0)], with: .fade)
                }
            }))
            
            setPopoverPresentationControllerInfo(alert, indexPath)
            alert.show()
        
        case .privacyPolicy:
            UIApplication.shared.open(privacyPolicyURL, options: [:], completionHandler: nil)
        
        case .termsOfService:
            UIApplication.shared.open(termsOfServiceURL, options: [:], completionHandler: nil)
        
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func getTriggerRect(_ cell: SettingCell) -> CGRect {
        return CGRect(x: cell.bounds.maxX - cell.valueLabel.width - 8,
                y: cell.bounds.minY,
                width: cell.valueLabel.width,
                height: cell.bounds.height)
    }
    
    private func setPopoverPresentationControllerInfo(_ alert: UIAlertController, _ indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)! as! SettingCell
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = getTriggerRect(cell)
        }
    }
    
    private func showSetPasswordAlert(_ indexPath: IndexPath) {
        tempPassword = nil
        
        let alert = UIAlertController(title: NSLocalizedString("setPassword", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        let okHandler: (UIAlertAction) -> Void = { action in
            if let lockType = self.tempLockType, let password = self.tempPassword, password.count > 0 && password == self.confirmPassword {
                SettingsManager.setLockCode(newLockCode: EncryptionUtil.sha512(initialData: password, salt: SettingsManager.CODE_SALT))
                SettingsManager.setLockType(lockType)
            }
            
            self.tableView.reloadRows(at: [IndexPath(row: Row.lockMode.rawValue, section: 0),
                                           IndexPath(row: Row.lockDelay.rawValue, section: 0)],
                    with: .fade)
            
            //Nilling the passwords so they aren't kept in memory
            self.tempPassword = nil
            self.confirmPassword = nil
            
            if let navigationController = self.parent as? UINavigationController, Auth.auth().currentUser == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let warningController = storyboard.instantiateViewController(withIdentifier: "Warning") as! WarningController
                warningController.modalPresentationStyle = .overFullScreen
                navigationController.present(warningController, animated: true, completion: nil)
            }
        }
        
        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: okHandler)
        okAction.isEnabled = false
        
        let configOne: AlertPasswordTextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = NSLocalizedString("setPassword", comment: "")
            textField.backgroundColor = nil
            textField.clearButtonMode = .whileEditing
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .next
            textField.showButtonWhile = PasswordTextField.ShowButtonWhile.Always
            
            textField.action { textField in
                self.tempPassword = textField.text
                okAction.isEnabled = self.tempPassword?.count > 0 && self.tempPassword == self.confirmPassword
            }
        }
        
        let configTwo: AlertPasswordTextField.Config = { textField in
            textField.textColor = .black
            textField.placeholder = NSLocalizedString("confirmPassword", comment: "")
            textField.backgroundColor = nil
            textField.clearsOnBeginEditing = true
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.showButtonWhile = PasswordTextField.ShowButtonWhile.Always
            
            self.tempTextFieldAction = TextFieldReturnAction({ _ in
                if (okAction.isEnabled) {
                    okHandler(okAction)
                    alert.dismiss(animated: true, completion: nil)
                }
                
                return false
            })
            textField.delegate = self.tempTextFieldAction
            
            textField.action { textField in
                self.confirmPassword = textField.text
                okAction.isEnabled = self.tempPassword?.count > 0 && self.tempPassword == self.confirmPassword
            }
        }
        alert.addTwoPasswordTextFields(textFieldOne: configOne, textFieldTwo: configTwo)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(okAction)
        
        setPopoverPresentationControllerInfo(alert, indexPath)
        alert.show()
    }
    
    private func showRemovePasswordAlert(_ indexPath: IndexPath) {
        tempPassword = nil
        
        let alert = UIAlertController(title: NSLocalizedString("enterPasswordToDisableLock", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        let okHandler: (UIAlertAction) -> Void = { action in
            if let password = self.tempPassword, password.count > 0 {
                let encryptedPassword = EncryptionUtil.sha512(initialData: password, salt: SettingsManager.CODE_SALT)
                
                if SettingsManager.getLockCode() == encryptedPassword {
                    SettingsManager.setLockCode(newLockCode: "")
                    SettingsManager.setLockType(LockType.off)
                } else {
                    self.view.makeToast(NSLocalizedString("incorrectPassword", comment: ""))
                }
            }
            
            self.tableView.reloadRows(at: [IndexPath(row: Row.lockMode.rawValue, section: 0),
                                           IndexPath(row: Row.lockDelay.rawValue, section: 0)],
                    with: .fade)
            
            //Nilling the password so they aren't kept in memory
            self.tempPassword = nil
        }
        
        let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: okHandler)
        okAction.isEnabled = false
        
        let config: AlertPasswordTextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = NSLocalizedString("enterPassword", comment: "")
            textField.backgroundColor = nil
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.showButtonWhile = PasswordTextField.ShowButtonWhile.Always
            
            self.tempTextFieldAction = TextFieldReturnAction({ _ in
                if (okAction.isEnabled) {
                    okHandler(okAction)
                    alert.dismiss(animated: true, completion: nil)
                }
                
                return false
            })
            textField.delegate = self.tempTextFieldAction
            
            textField.action { textField in
                self.tempPassword = textField.text
                okAction.isEnabled = self.tempPassword?.count > 0
            }
        }
        alert.addOnePasswordTextField(configuration: config)
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(okAction)
        
        setPopoverPresentationControllerInfo(alert, indexPath)
        alert.show()
    }
}

extension SettingsController: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if error != nil || authDataResult == nil {
            view.makeToast(NSLocalizedString("signInError", comment: ""))
            return
        }
        
        if Auth.auth().currentUser != nil {
            SettingsManager.attemptFirebaseAutoSetup()
        }
        
        tableView.reloadRows(at: [IndexPath(row: Row.account.rawValue, section: 0)], with: .fade)
    }
}

extension SettingsController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if urls.count > 1 {
            //Selected more than one file
            AlertHelper.showMessage(
                    title: NSLocalizedString("error", comment: ""),
                    message: NSLocalizedString("importErrorTooMany", comment: "")
            )
        } else if let url = urls.first, !appDelegate.handleImportingBackup(url) {
            //Selected a file that isn't a TransTracks backup
            AlertHelper.showMessage(
                    title: NSLocalizedString("error", comment: ""),
                    message: NSLocalizedString("importError", comment: "")
            )
        }
    }
}
