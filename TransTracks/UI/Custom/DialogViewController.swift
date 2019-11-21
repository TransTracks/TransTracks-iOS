//
//  DialogViewController.swift
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

class DialogViewController : UIViewController {
    
    //MARK: UI Helpers
    
    func addDropShadow(_ background: UIView){
        background.layer.cornerRadius = 4.0
        background.layer.masksToBounds = false
        
        background.layer.shadowColor = UIColor.black.cgColor
        background.layer.shadowOpacity = 0.5
        background.layer.shadowRadius = 3
        background.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    func enableTouchOutsideToDismiss(){
        let touchOutside = UITapGestureRecognizer(target: self, action: #selector(handleTouchOutside))
        view.addGestureRecognizer(touchOutside)
    }
    
    //MARK: Button handling
    
    @objc func handleTouchOutside(){
        dismiss(animated: true)
    }
}
