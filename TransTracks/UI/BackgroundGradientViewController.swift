//
//  GradientBackgroundViewController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 17/2/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class BackgroundGradientViewController: UIViewController {
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBackgroundGradient()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setBackgroundGradient()
    }
    
    //MARK: UI helpers
    
    func setBackgroundGradient(_ theme: Theme = UserDefaultsUtil.getTheme()){
        let newGradient = ThemeManager.getBackgroundGradient(theme)
        newGradient.frame = view.frame
        
        if let oldGradient = view.layer.sublayers?[0], oldGradient is CAGradientLayer {
            view.layer.replaceSublayer(oldGradient, with: newGradient)
        } else {
            view.layer.insertSublayer(newGradient, at: 0)
        }
    }
}
