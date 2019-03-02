//
//  OnePasswordTextFieldController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 23/2/19.
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

extension UIAlertController {
    
    /// Add a textField
    ///
    /// - Parameters:
    ///   - height: textField height
    ///   - hInset: right and left margins to AlertController border
    ///   - vInset: bottom margin to button
    ///   - configuration: textField
    
    func addOnePasswordTextField(configuration: AlertPasswordTextField.Config?) {
        let textField = OnePasswordTextFieldViewController(vInset: preferredStyle == .alert ? 12 : 0, configuration: configuration)
        let height: CGFloat = OnePasswordTextFieldViewController.ui.height + OneTextFieldViewController.ui.vInset
        set(vc: textField, height: height)
    }
}

final class OnePasswordTextFieldViewController: UIViewController {
    
    fileprivate lazy var textField: AlertPasswordTextField = AlertPasswordTextField()
    
    struct ui {
        static let height: CGFloat = 44
        static let hInset: CGFloat = 12
        static var vInset: CGFloat = 12
    }
    
    
    init(vInset: CGFloat = 12, configuration: AlertPasswordTextField.Config?) {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(textField)
        ui.vInset = vInset
        
        /// have to set textField frame width and height to apply cornerRadius
        textField.height = ui.height
        textField.width = view.width
        
        configuration?(textField)
        
        preferredContentSize.height = ui.height + ui.vInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Log("has deinitialized")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        textField.width = view.width - ui.hInset * 2
        textField.height = ui.height
        textField.center.x = view.center.x
        textField.center.y = view.center.y - ui.vInset / 2
    }
}
