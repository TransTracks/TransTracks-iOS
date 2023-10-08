//
//  TrainLockController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 10/5/19.
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

class TrainLockController: UIViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    
    //MARK: Outlets
    
    @IBOutlet weak var reportingNumber: UITextField!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setupViewResizerOnKeyboardShown()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            if SettingsManager.saveToFirebase(){
                SettingsManager.enableFirebaseSync()
            }
        }
    }
    
    //MARK: Button Handling
    
    @IBAction func searchClick(_ sender: Any) {
        let encryptedPassword = EncryptionUtil.sha512(initialData: reportingNumber.text ?? "", salt: SettingsManager.CODE_SALT)
        
        if(SettingsManager.getLockCode() == encryptedPassword){
            navigationController?.popViewController(animated: true)
            SettingsManager.resetIncorrectPasswordCount()
        } else {
            view.makeToast(NSLocalizedString("incorrectTrain", comment: ""))
            SettingsManager.incrementIncorrectPasswordCount()
            
            if SettingsManager.showAccountWarning() && SettingsManager.getIncorrectPasswordCount() >= 25 {
                performSegue(withIdentifier: "OneChance", sender: nil)
            }
        }
    }
}
