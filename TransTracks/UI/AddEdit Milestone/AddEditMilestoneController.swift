//
//  AddEditMilestoneController.swift
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

import Toast_Swift
import UIKit

class AddEditMilestoneController: BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    
    var milestone: Milestone?
    var initialEpochDay: Int!
    
    private var currentDate: Date = Date()
    
    //MARK: Outlets
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateValue: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewResizerOnKeyboardShown()
        setupCallbacks()
        
        if let milestone = milestone {
            currentDate = Date.ofEpochDay(milestone.epochDay)
            
            title = NSLocalizedString("editMilestone", comment: "")
            
            titleTextField.text = milestone.title
            descriptionTextField.text = milestone.userDescription
            saveButton.setTitle(NSLocalizedString("editMilestone", comment: ""), for: .normal)
        } else {
            currentDate = Date.ofEpochDay(initialEpochDay)
            
            title = NSLocalizedString("addMilestone", comment: "")
            navigationItem.setRightBarButton(nil, animated: false)
            
            saveButton.setTitle(NSLocalizedString("addMilestone", comment: ""), for: .normal)
        }
        
        updateDateValue()
    }
    
    //MARK: UI Helpers
    
    private func setupCallbacks(){
        let dateTap = UITapGestureRecognizer(target: self, action: #selector(dateClick(_:)))
        dateValue.addGestureRecognizer(dateTap)
        
        let descriptionTap = UITapGestureRecognizer(target: self, action: #selector(descriptionFocus(_:)))
        descriptionLabel.addGestureRecognizer(descriptionTap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateDescriptionBackground), name: UITextView.textDidBeginEditingNotification, object: descriptionTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDescriptionBackground), name: UITextView.textDidEndEditingNotification, object: descriptionTextField)
    }
    
    @objc func updateDescriptionBackground(){
        if descriptionTextField.isFirstResponder {
            descriptionTextField.backgroundColor = UIColor.black.withAlphaComponent(0.10)
        } else {
            descriptionTextField.backgroundColor = UIColor.clear
        }
    }
    
    func updateDateValue(){
        dateValue.text = currentDate.toFullDateString()
    }
    
    //MARK: Button Handling
    
    @IBAction func deleteClick(_ sender: Any) {
        guard let milestone = milestone else { return }
        
        let alert = UIAlertController(style: .alert, title: NSLocalizedString("areYouSure", comment: ""), message: NSLocalizedString("deleteMilestoneWarningMessage", comment: ""))
        alert.addAction(UIAlertAction(title:  NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { [unowned self] _ in
            self.alertController?.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { [unowned self] _ in
            self.domainManager.dataController.backgroundContext.delete(milestone)
            try? self.domainManager.dataController.backgroundContext.save()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.show()
    }
    
    @objc func dateClick(_ sender: Any){
        AlertHelper.showDatePicker(startingDate: currentDate, triggeringView: dateValue){ newDate in
            self.currentDate = newDate
            self.updateDateValue()
        }
    }
    
    @objc func descriptionFocus(_ sender: Any){
        descriptionTextField.becomeFirstResponder()
    }
    
    @IBAction func saveClick(_ sender: Any) {
        var milestoneToSave = milestone
        
        if milestoneToSave == nil {
          milestoneToSave = Milestone(context: domainManager.dataController.backgroundContext)
        }
        
        milestoneToSave!.id = UUID()
        milestoneToSave!.timestamp = Date()
        milestoneToSave!.epochDay = Int64(currentDate.toEpochDay())
        milestoneToSave!.title = titleTextField.text
        milestoneToSave!.userDescription = descriptionTextField.text
        
        do {
            try domainManager.dataController.backgroundContext.save()
            
            if milestone != nil {
                view.makeToast(NSLocalizedString("savedMilestone", comment: ""))
            } else {
                view.makeToast(NSLocalizedString("updatedMilestone", comment: ""))
            }
            
            navigationController?.popViewController(animated: true)
        } catch {
            print(error)
            
            if milestone != nil {
                view.makeToast(NSLocalizedString("errorSavingMilestone", comment: ""))
            } else {
                view.makeToast(NSLocalizedString("errorUpdatingMilestone", comment: ""))
            }
        }
    }
}
