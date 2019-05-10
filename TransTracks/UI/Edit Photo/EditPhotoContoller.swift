//
//  EditPhotoContoller.swift
//  TransTracks
//
//  Created by Cassie Wilson on 4/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import RxCocoa
import RxSwift
import RxSwiftExt
import Toast_Swift
import UIKit

class EditPhotoController : BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    var photo: Photo!
    
    private var resultsDisposable: Disposable?
    private var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var interactionEnabled: Bool = true
    
    //MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLabelTapRecognizers()
        
        resultsDisposable = domainManager.editPhotoDomain.results
            .do(onSubscribe: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.domainManager.editPhotoDomain.actions.accept(.InitialData(photo: self.photo))
                }
            })
            .subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let _ = viewDisposables.insert(
            domainManager.editPhotoDomain.results.subscribe{ result in
                guard let result = result.element else { return }
                
                switch result {
                case .Display(let image, let date, let type):
                    if let image = image {
                        self.imageView.image = UIImage(contentsOfFile: image.path)
                    } else {
                        self.imageView.image = nil
                    }
                    
                    self.dateLabel.text = date.toFullDateString()
                    self.typeLabel.text = type.getDisplayName()
                    
                    self.updateUIEnabled(true)
                    
                case .Saving:
                    self.updateUIEnabled(false)
                }
            }
        )
        
        let _ = viewDisposables.insert(
            domainManager.editPhotoDomain.viewEffects.subscribe{ effect in
                guard let effect = effect.element else { return }
                
                switch effect {
                case .ShowDateDialog(let currentDate):
                    AlertHelper.showDatePicker(startingDate: currentDate, triggeringView: self.dateLabel){ newDate in
                        self.domainManager.editPhotoDomain.actions.accept(.ChangeDate(newDate: newDate))
                    }
                    
                case .ShowTypeDialog(let currentType):
                    AlertHelper.showPhotoTypePicker(startingType: currentType, triggeringView: self.typeLabel){ newType in
                        self.domainManager.editPhotoDomain.actions.accept(.ChangeType(newType: newType))
                    }
                    
                case .SaveSuccess:
                    self.view.makeToast(NSLocalizedString("savedPhoto", comment: ""))
                    self.navigationController?.popViewController(animated: true)
                    
                case .SaveFailure:
                    self.view.makeToast(NSLocalizedString("errorSavingPhoto", comment: ""))
                }
            }
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDisposables.dispose()
        viewDisposables = CompositeDisposable()
    }
    
    deinit {
        resultsDisposable?.dispose()
    }
    
    //MARK: UI Helpers
    
    private func setupLabelTapRecognizers(){
        let dateTap = UITapGestureRecognizer(target: self, action: #selector(dateClick(_:)))
        dateLabel.addGestureRecognizer(dateTap)
        
        let typeTap = UITapGestureRecognizer(target: self, action: #selector(typeClick(_:)))
        typeLabel.addGestureRecognizer(typeTap)
    }
    
    private func updateUIEnabled(_ enabled: Bool){
        interactionEnabled = enabled
        updateButton.isEnabled = enabled
    }
    
    //MARK: Button handling
    
    @objc func dateClick(_ sender: Any){
        guard interactionEnabled else { return }
        
        domainManager.editPhotoDomain.actions.accept(.ShowDateDialog)
    }
    
    @objc func typeClick(_ sender: Any){
        guard interactionEnabled else { return }
        
        domainManager.editPhotoDomain.actions.accept(.ShowTypeDialog)
    }
    
    @IBAction func updateClick(_ sender: Any) {
        domainManager.editPhotoDomain.actions.accept(.Save)
    }
}
