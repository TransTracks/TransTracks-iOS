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

import PasswordTextField
import UIKit

class SettingsController: BackgroundGradientViewController {
    
    //MARK: Properties
    private var tempDate: Date?
    private var tempTheme: Theme?
    private var tempLockType: LockType?
    private var tempPassword: String?
    private var confirmPassword: String?
    private var tempLockDelay: LockDelay?
    
    private var tempTextFieldAction: TextFieldReturnAction?
    
    //MARK: Outlets
    
    @IBOutlet weak var adViewHolder: AdContainerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var copyrightLabel: UILabel!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adViewHolder.setupAd("ca-app-pub-4389848400124499/9443250102", rootViewController: self)
        
        navigationItem.titleView?.tintColor = UIColor.white
        copyrightLabel.text = String(format: NSLocalizedString("copyrightWithCurrentYear", comment: ""), Date.getCurrentYear())
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
        case .setting: configSettingRow(cell as! SettingCell, row)
        case .divider: break //Divider cells don't need configuring
        case .button: configButtonRow(cell as! ButtonCell, row)
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
        case .setting: identifier = "SettingCell"
        case .divider: identifier = "Divider"
        case .button: identifier = "ButtonCell"
        }
        
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = Row(rawValue: indexPath.row)!.getRowType()
        
        switch rowType {
        case .setting: return 50
        case .divider: return 2
        case .button: return 50
        }
    }
    
    private func configSettingRow(_ cell: SettingCell, _ row: Row) {
        let title: String
        let value: String
        var description: String?
        
        var rowEnabled = true
        
        switch row {
        case .startDate:
            title = NSLocalizedString("startDateLabel", comment: "")
            value = UserDefaultsUtil.getStartDate().toFullDateString()
        
        case .theme:
            title = NSLocalizedString("themeLabel", comment: "")
            value = UserDefaultsUtil.getTheme().getDisplayName()
        
        case .lockMode:
            title = NSLocalizedString("lockModeLabel", comment: "")
            value = UserDefaultsUtil.getLockType().getDisplayName()
            description = NSLocalizedString("lockModeDescription", comment: "")
        
        case .lockDelay:
            title = NSLocalizedString("lockDelayLabel", comment: "")
            value = UserDefaultsUtil.getLockDelay().getDisplayName()
            
            rowEnabled = UserDefaultsUtil.getLockType() != LockType.off
        
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
        
        default:
            fatalError("This row hasn't been configured")
        }
        
        cell.titleLabel.text = title
    }
    
    enum Row: Int, CaseIterable {
        case startDate
        case theme
        case lockMode
        case lockDelay
        case divider1
        case appVersion
        case privacyPolicy
        
        func getRowType() -> RowType {
            switch self {
            case .startDate: return .setting
            case .theme: return .setting
            case .lockMode: return .setting
            case .lockDelay: return .setting
            case .divider1: return .divider
            case .appVersion: return .setting
            case .privacyPolicy: return .button
            }
        }
    }
    
    enum RowType {
        case setting, divider, button
    }
}

extension SettingsController: UITableViewDelegate {
    //Block selection of divider rows
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = Row(rawValue: indexPath.row)!
        
        if row == .appVersion || // The App version cannot be clicked
            row.getRowType() == RowType.divider || // Dividers cannot be clicked
            (row == .lockDelay && UserDefaultsUtil.getLockType() == .off) { //If the lock type is set to OFF then the user cannot change the lock delay
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)!
        
        switch row {
        case .startDate:
            tempDate = nil
            
            let alert = UIAlertController(title: NSLocalizedString("selectStartDateTitle", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addDatePicker(mode: .date, date: UserDefaultsUtil.getStartDate(), action: {date in
                self.tempDate = date
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let newDate = self.tempDate {
                    UserDefaultsUtil.setStartDate(newDate)
                    tableView.reloadRows(at: [IndexPath(row: Row.startDate.rawValue, section: 0)], with: .fade)
                }
            }))
            
            setPopoverPresentationControllerInfo(alert, indexPath)
            alert.show()
            
        case .theme:
            tempTheme = nil
            
            let alert = UIAlertController(title: NSLocalizedString("selectTheme", comment: ""), message: nil, preferredStyle: .actionSheet)
            alert.addPickerView(values: [Theme.getDisplayNamesArray()], initialSelection: (column: 0, row: UserDefaultsUtil.getTheme().getIndex()), action: {_, _ , index, _ in
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
                    UserDefaultsUtil.setTheme(newTheme)
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
            alert.addPickerView(values: [LockType.getDisplayNamesArray()], initialSelection: (column: 0, row: UserDefaultsUtil.getLockType().getIndex()), action: {_, _ , index, _ in
                self.tempLockType = LockType.allCases[index.row]
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let newLockType = self.tempLockType {
                    let currentLockType = UserDefaultsUtil.getLockType()
                    
                    if newLockType != currentLockType {
                        let hasCode = !UserDefaultsUtil.getLockCode().isEmpty
                        
                        if newLockType == .off {
                            //Turn off lock, and remove the code
                            self.showRemovePasswordAlert(indexPath)
                        } else if hasCode {
                            UserDefaultsUtil.setLockType(newLockType)
                            
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
            alert.addPickerView(values: [LockDelay.getDisplayNamesArray()], initialSelection: (column: 0, row: UserDefaultsUtil.getLockDelay().getIndex()), action: {_, _ , index, _ in
                self.tempLockDelay = LockDelay.allCases[index.row]
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                if let tempLockDelay = self.tempLockDelay {
                    UserDefaultsUtil.setLockDelay(tempLockDelay)
                    tableView.reloadRows(at: [IndexPath(row: Row.lockDelay.rawValue, section: 0)], with: .fade)
                }
            }))
            
            setPopoverPresentationControllerInfo(alert, indexPath)
            alert.show()
            
        case .privacyPolicy:
            UIApplication.shared.open(URL(string: "http://www.drspaceboo.com/privacy-policy/")!, options: [:], completionHandler: nil)
            
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setPopoverPresentationControllerInfo(_ alert: UIAlertController, _ indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath)! as! SettingCell
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = CGRect(x: cell.frame.maxX - cell.valueLabel.width - 8,
                                                  y: cell.frame.minY,
                                                  width: cell.valueLabel.width,
                                                  height: cell.frame.height)
        }
    }
    
    private func showSetPasswordAlert(_ indexPath: IndexPath){
        tempPassword = nil
        
        let alert = UIAlertController(title: NSLocalizedString("setPassword", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        let okHandler: (UIAlertAction) -> Void = { action in
            if let lockType = self.tempLockType, let password = self.tempPassword, password.count > 0 && password == self.confirmPassword {
                UserDefaultsUtil.setLockCode(newLockCode: EncryptionUtil.sha512(initialData: password, salt: UserDefaultsUtil.CODE_SALT))
                UserDefaultsUtil.setLockType(lockType)
            }
            
            self.tableView.reloadRows(at: [IndexPath(row: Row.lockMode.rawValue, section: 0),
                                           IndexPath(row: Row.lockDelay.rawValue, section: 0)],
                                      with: .fade)
            
            //Nilling the passwords so they aren't kept in memory
            self.tempPassword = nil
            self.confirmPassword = nil
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
                if(okAction.isEnabled){
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
    
    private func showRemovePasswordAlert(_ indexPath: IndexPath){
        tempPassword = nil

        let alert = UIAlertController(title: NSLocalizedString("enterPasswordToDisableLock", comment: ""), message: nil, preferredStyle: .actionSheet)
        
        let okHandler: (UIAlertAction) -> Void = { action in
            if let password = self.tempPassword, password.count > 0 {
                let encryptedPassword = EncryptionUtil.sha512(initialData: password, salt: UserDefaultsUtil.CODE_SALT)
                
                if(UserDefaultsUtil.getLockCode() == encryptedPassword){
                    UserDefaultsUtil.setLockCode(newLockCode: "")
                    UserDefaultsUtil.setLockType(LockType.off)
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
                if(okAction.isEnabled){
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
