//
//  ThemedDatePicker.swift
//  TransTracks
//
//  Created by Cassie Wilson on 17/6/23.
//  Copyright © 2023 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class ThemedDatePicker: UIDatePicker {
    
    var onDateChange: ((Date) -> Void)? = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        let theme = SettingsManager.getTheme()
        
        tintColor = .white
        backgroundColor = theme.colorAccent
        textColor = .white
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        
        layer.cornerRadius = 4.0
        layer.masksToBounds = false

        addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
    }
    
    @objc func datePickerChanged() {
        guard let onDateChange = onDateChange else {
            return
        }
        
        onDateChange(date)
    }
}
