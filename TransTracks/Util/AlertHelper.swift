//
//  AlertHelper.swift
//  TransTracks
//
//  Created by Cassie Wilson on 9/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class AlertHelper {
    private static var tempDate: Date?
    private static var tempPhotoType: PhotoType?
    
    static func showDatePicker(startingDate: Date, maximumDate: Date? = Date(), triggeringView: UIView, specificTriggerRect: CGRect? = nil, applyChange: @escaping (Date) -> ()) {
        AlertHelper.tempDate = nil
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addDatePicker(mode: .date, date: startingDate, maximumDate: maximumDate, action: { date in
            AlertHelper.tempDate = date
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
            if let newDate = self.tempDate {
                applyChange(newDate)
            }
        }))
        
        setPopoverPresentationControllerInfo(alert, triggeringView, specificTriggerRect)
        alert.show()
    }
    
    static func showMessage(title: String, message: String? = nil, okHandler: ((UIAlertAction) -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: okHandler))
        alert.show()
    }
    
    static func showPhotoTypePicker(startingType: PhotoType, triggeringView: UIView, specificTriggerRect: CGRect? = nil, applyChange: @escaping (PhotoType) -> ()) {
        self.tempPhotoType = nil
        
        let alert = UIAlertController(title: NSLocalizedString("selectType", comment: ""), message: nil, preferredStyle: .actionSheet)
        alert.addPickerView(values: [PhotoType.getDisplayNamesArray()], initialSelection: (column: 0, row: startingType.getIndex()), action: { _, _, index, _ in
            self.tempPhotoType = PhotoType.allCases[index.row]
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
            if let newType = self.tempPhotoType {
                applyChange(newType)
            }
        }))
        
        self.setPopoverPresentationControllerInfo(alert, triggeringView, specificTriggerRect)
        alert.show()
    }
    
    private static func setPopoverPresentationControllerInfo(_ alert: UIAlertController, _ view: UIView, _ specificTrigerRect: CGRect?) {
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            
            if let specificTrigerRect = specificTrigerRect {
                popoverController.sourceRect = specificTrigerRect
            } else {
                popoverController.sourceRect = view.bounds
            }
        }
    }
}
