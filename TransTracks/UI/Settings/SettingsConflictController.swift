//
//  SettingsConflictController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 31/8/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class SettingsConflictController: DialogViewController {
    //MARK: Static properties
    private static let CELL_HEIGHT:CGFloat = 50
    
    //MARK: Properties
    var differences: [(SettingsManager.Key, Any)]!
    var choices: [Bool]!
    
    //MARK: Outlets
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var applyButton: ThemedButton!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDropShadow(background)
        
        choices = Array(repeating: true, count: differences.count)
        tableView.dataSource = self
        tableView.delegate = self
        
        var height: CGFloat = SettingsConflictController.CELL_HEIGHT * CGFloat(differences.count)
        
        if height > 280 {
            height = 280
        }
        
        tableViewHeight.constant = height
    }
    
    //MARK: Handle button
    
    @IBAction func applyClick(_ sender: Any) {
        var data: [String: Any] = [:]
        
        for (index, (key, value)) in differences.enumerated() {
            if choices[index] {
                data[key.rawValue] = value
            } else {
                data[key.rawValue] = SettingsManager.firebaseValueForKey(key)
            }
        }
        
        let docRef = try! FirebaseSettingUtil.getSettingsDocRef()
        
        docRef.setData(data, merge: true)
        SettingsManager.enableFirebaseSync()
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsConflictController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return differences.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingConflictCell", for: indexPath) as! SettingConflictCell
        let (key, serverConflictValue) = differences[indexPath.row]
        let useSever = choices[indexPath.row]
        
        let name: String
        let localValue: String
        let serverValue: String
        
        switch key {
        case .lockCode:
            name = NSLocalizedString("lockCodeLabel", comment: "")
            
            if SettingsManager.getLockCode().isEmpty {
                localValue = NSLocalizedString("noCode", comment: "")
            } else {
                localValue = NSLocalizedString("useLocalCode", comment: "")
            }
            
            if (serverConflictValue as! String).isEmpty {
                serverValue = NSLocalizedString("noCode", comment: "")
            } else {
                serverValue = NSLocalizedString("useServerCode", comment: "")
            }
                
        case .lockDelay:
            name = NSLocalizedString("lockDelayLabel", comment: "")
            localValue = SettingsManager.getLockDelay().getDisplayName()
            serverValue = LockDelay(rawValue: serverConflictValue as! String)!.getDisplayName()
            
        case .lockType:
            name = NSLocalizedString("lockModeLabel", comment: "")
            localValue = SettingsManager.getLockType().getDisplayName()
            serverValue = LockType(rawValue: serverConflictValue as! String)!.getDisplayName()

        case .startDate:
            name = NSLocalizedString("startDateLabel", comment: "")
            localValue = SettingsManager.getStartDate().toFullDateString()
            serverValue = Date.ofEpochDay(serverConflictValue as! Int).toFullDateString()
            
        case .theme:
            name = NSLocalizedString("themeLabel", comment: "")
            localValue = SettingsManager.getTheme().getDisplayName()
            serverValue = Theme(rawValue: serverConflictValue as! String)!.getDisplayName()

        case .currentiOSVersion, .incorrectPasswordCount, .saveToFirebase, .showAccountWarning, .showAds, .showWelcome, .userLastSeen:
            fatalError("This settings should not be in conflict because they don't get synced")
        }
        
        cell.settingsName.text = name
        
        cell.segmentChoices.setTitle(localValue, forSegmentAt: 0)
        cell.segmentChoices.setTitle(serverValue, forSegmentAt: 1)
        
        if useSever {
            cell.segmentChoices.selectedSegmentIndex = 1
        } else {
            cell.segmentChoices.selectedSegmentIndex = 0
        }
        
        cell.segmentChoices.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
        
        return cell
    }
    
    @objc func switchChanged(sender: UISegmentedControl!){
        if let cell = sender.superview?.superview as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            let row = indexPath.row
            choices[row] = sender.selectedSegmentIndex == 1
            let (key, serverValue) = differences[row]
            var rowsToUpdate: [IndexPath] = []
            rowsToUpdate.append(indexPath)
            
            if key == .lockCode && ((serverValue as! String).isEmpty || SettingsManager.getLockCode().isEmpty), let typeIndex = indexOfKey(.lockType) {
                choices[typeIndex] = choices[row]
                rowsToUpdate.append(IndexPath(row: typeIndex, section: 0))
            } else if key == .lockType && (LockType(rawValue: (serverValue as! String)) == .off || SettingsManager.getLockType() == .off), let codeIndex = indexOfKey(.lockCode) {
                choices[codeIndex] = choices[row]
                rowsToUpdate.append(IndexPath(row: codeIndex, section: 0))
            }
            
            tableView.reloadRows(at: rowsToUpdate, with: .fade)
        }
    }
    
    private func indexOfKey(_ key: SettingsManager.Key) -> Int? {
        for (index, (keyInArray, _)) in differences.enumerated() {
            if key == keyInArray {
                return index
            }
        }
        
        return nil
    }
}

extension SettingsConflictController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SettingsConflictController.CELL_HEIGHT
    }
}
