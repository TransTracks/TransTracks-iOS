//
//  WarningViewController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 21/11/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class WarningController: DialogViewController {
    
    //MARK: Outlets
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var createAccountButton: ThemedButton!
    @IBOutlet weak var riskItButton: DropShadowButton!
    
    //MARK:Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDropShadow(background)
        
        createAccountButton.enableAutoSizeText()
        riskItButton.enableAutoSizeText()
    }
    
    //MARK: Button handling
    
    @IBAction func createAccountClick(_ sender: Any) {
        if let navController = self.presentingViewController as? NavigationController, let homeController = navController.topViewController as? HomeViewController {
            dismiss(animated: true, completion: {
                SettingsManager.setAccountWarning(false)
                homeController.performSegue(withIdentifier: "Settings", sender: true)
            })
        }
    }
    
    @IBAction func riskItClick(_ sender: Any) {
        SettingsManager.setAccountWarning(false)
        dismiss(animated: true)
    }
}
