//
//  TwoPasswordTextFieldController.swift
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

import Foundation
import PasswordTextField
import UIKit

extension UIAlertController {
    
    /// Add two textField
    ///
    /// - Parameters:
    ///   - height: textField height
    ///   - hInset: right and left margins to AlertController border
    ///   - vInset: bottom margin to button
    ///   - textFieldOne: first textField
    ///   - textFieldTwo: second textField
    
    func addTwoPasswordTextFields(height: CGFloat = 58, hInset: CGFloat = 0, vInset: CGFloat = 0, textFieldOne: AlertPasswordTextField.Config?, textFieldTwo: AlertPasswordTextField.Config?) {
        let textField = TwoPasswordTextFieldsViewController(height: height, hInset: hInset, vInset: vInset, textFieldOne: textFieldOne, textFieldTwo: textFieldTwo)
        set(vc: textField, height: height * 2 + 2 * vInset)
    }
}

final class TwoPasswordTextFieldsViewController: UIViewController, UITextFieldDelegate {
    
    fileprivate lazy var textFieldView: UIView = UIView()
    fileprivate lazy var textFieldOne: AlertPasswordTextField = AlertPasswordTextField()
    fileprivate lazy var textFieldTwo: AlertPasswordTextField = AlertPasswordTextField()
    
    fileprivate var height: CGFloat
    fileprivate var hInset: CGFloat
    fileprivate var vInset: CGFloat
    
    init(height: CGFloat, hInset: CGFloat, vInset: CGFloat, textFieldOne configurationOneFor: AlertPasswordTextField.Config?, textFieldTwo configurationTwoFor: AlertPasswordTextField.Config?) {
        self.height = height
        self.hInset = hInset
        self.vInset = vInset
        super.init(nibName: nil, bundle: nil)
        view.addSubview(textFieldView)
        
        textFieldOne.delegate = self 
        
        textFieldView.addSubview(textFieldOne)
        textFieldView.addSubview(textFieldTwo)
        
        textFieldView.width = view.width
        textFieldView.height = height * 2
        textFieldView.maskToBounds = true
        textFieldView.borderWidth = 1
        textFieldView.borderColor = UIColor.lightGray
        textFieldView.cornerRadius = 8
        
        configurationOneFor?(textFieldOne)
        configurationTwoFor?(textFieldTwo)
        
        //preferredContentSize.height = height * 2 + vInset
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
        
        textFieldView.width = view.width - hInset * 2
        textFieldView.height = height * 2
        textFieldView.center.x = view.center.x
        textFieldView.center.y = view.center.y
        
        textFieldOne.width = textFieldView.width
        textFieldOne.height = textFieldView.height / 2
        textFieldOne.center.x = textFieldView.width / 2
        textFieldOne.center.y = textFieldView.height / 4
        
        textFieldTwo.width = textFieldView.width
        textFieldTwo.height = textFieldView.height / 2
        textFieldTwo.center.x = textFieldView.width / 2
        textFieldTwo.center.y = textFieldView.height - textFieldView.height / 4
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldOne && textFieldOne.returnKeyType == .next {
            textFieldTwo.becomeFirstResponder()
            return false
        }
        
        return true
    }
}

