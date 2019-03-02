//
//  AlertPasswordTextField.swift
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

open class AlertPasswordTextField: PasswordTextField {
    
    public typealias Config = (AlertPasswordTextField) -> Swift.Void
    
    public func configure(configurate: Config?) {
        configurate?(self)
    }
    
    public typealias Action = (UITextField) -> Void
    
    fileprivate var actionEditingChanged: Action?
    
    // Provides left padding for images
    
    override open func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += leftViewPadding ?? 0
        return textRect
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: (leftTextPadding ?? 8) + (leftView?.width ?? 0) + (leftViewPadding ?? 0), dy: 0)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: (leftTextPadding ?? 8) + (leftView?.width ?? 0) + (leftViewPadding ?? 0), dy: 0)
    }
    
    
    public var leftViewPadding: CGFloat?
    public var leftTextPadding: CGFloat?
    
    
    public func action(closure: @escaping Action) {
        if actionEditingChanged == nil {
            addTarget(self, action: #selector(TextField.textFieldDidChange), for: .editingChanged)
        }
        actionEditingChanged = closure
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        actionEditingChanged?(self)
    }
}
