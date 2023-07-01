//
//  AssignPhotoController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 16/4/19.
//  Copyright © 2019-2023 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Photos
import RxCocoa
import RxSwift
import RxSwiftExt
import Toast
import UIKit

class AssignPhotoController : BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    
    var image: UIImage?
    var photos: [PHAsset]?
    
    var epochDay: Int?
    var type: PhotoType = PhotoType.face
    
    private var resultsDisposable: Disposable?
    private var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var currentAsset: PHAsset? = nil
    private var currentPhotoDate: Date? = nil
    private var currentIndex: Int = 0
    private var currentCount: Int = 0
    
    private var interactionEnabled: Bool = true
    
    //MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var datePicker: ThemedDatePicker!
    @IBOutlet weak var usePhotoDate: UIButton!
    @IBOutlet weak var usePhotoDateWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLabelTapRecognizers()
        
        resultsDisposable = domainManager.assignPhotoDomain.results.do(onSubscribe: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.domainManager.assignPhotoDomain.actions.accept(.InitialData(photos: self.photos, image: self.image, epochDay: self.epochDay, type: self.type))
            }
        }).subscribe()
            
        datePicker.onDateChange = { [weak self] newDate in
            guard let self = self else { return }
            self.domainManager.assignPhotoDomain.actions.accept(.ChangeDate(index: self.currentIndex, newDate: newDate))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let _ = viewDisposables.insert(
            domainManager.assignPhotoDomain.results.subscribe{ result in
                guard let result = result.element else { return }
                
                switch result {
                case .Loading(_, let count):
                    self.updateSkipVisibility(count: count)
                    self.updateUIEnabled(false)
                    
                case .Display(let asset, let image, let date, let photoDate, let type, let index, let count):
                    self.display(asset: asset, image: image, date: date, photoDate: photoDate, type: type, index: index, count: count)
                    self.updateUIEnabled(true)
                    
                case .SavingImage(let asset, let image, let date, let photoDate, let type, let index, let count):
                    self.display(asset: asset, image: image, date: date, photoDate: photoDate, type: type, index: index, count: count)
                    self.updateUIEnabled(false)
                }
            }
        )
        
        let _ = viewDisposables.insert(
            domainManager.assignPhotoDomain.viewEffects.subscribe{ viewEffect in
                guard let viewEffect = viewEffect.element else { return }
                
                DispatchQueue.main.async {
                    switch viewEffect {
                        
                    case .ShowTypeDialog(let type):
                        AlertHelper.showPhotoTypePicker(startingType: type, triggeringView: self.typeLabel){ newType in
                            self.domainManager.assignPhotoDomain.actions.accept(.ChangeType(index: self.currentIndex, newType: newType))
                        }
                        
                    case .ShowSaveSuccess:
                        self.view.makeToast(NSLocalizedString("savedPhoto", comment: ""))
                        
                    case .ShowSaveError:
                        self.view.makeToast(NSLocalizedString("errorSavingPhoto", comment: ""))
                        
                    case .ShowSkipMessage:
                        self.view.makeToast(NSLocalizedString("skippedPhoto", comment: ""))
                        
                    case .CompletedAssigning:
                        if let galleryController = self.navigationController?.viewControllers.first(where: {$0 is GalleryController}) as? GalleryController {
                            self.navigationController?.popToViewController(galleryController, animated: true)
                        } else {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
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
    
    private func display(asset: PHAsset?, image: UIImage?, date: Date, photoDate: Date?, type: PhotoType, index: Int, count: Int){
        currentPhotoDate = photoDate
        currentIndex = index
        currentCount = count
        
        if let image = image {
            self.imageView.image = image
        } else if let asset = asset {
            if currentAsset != asset {
                currentAsset = asset
                Assets.resolve(asset: asset, size: imageView.bounds.size, contentMode: .aspectFit){ newPhoto in
                    self.imageView.image = newPhoto
                }
            }
        } else {
            fatalError("Image or Asset needs to be set")
        }
        
        datePicker.date = date
        
        let hideUsePhotoDate: Bool = photoDate == nil || Calendar.current.isDate(date, inSameDayAs:photoDate!)
        
        usePhotoDate.isHidden = hideUsePhotoDate
        usePhotoDateWidthConstraint.constant = hideUsePhotoDate ? 0 : 48
        
        typeLabel.text = type.getDisplayName()
        updateSkipVisibility(count: count)
    }
    
    private func setupLabelTapRecognizers(){
        typeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(typeClick(_:))))
    }
    
    private func updateSkipVisibility(count: Int){
        skipButton.isHidden = count == 1
    }
    
    private func updateUIEnabled(_ enabled: Bool){
        interactionEnabled = enabled
        
        usePhotoDate.isEnabled = enabled
        saveButton.isEnabled = enabled
        skipButton.isEnabled = enabled
    }
    
    //MARK: Button handling
    
    @IBAction func usePhotoDateClick(_ sender: Any) {
        if let currentPhotoDate = currentPhotoDate {
            domainManager.assignPhotoDomain.actions.accept(.ChangeDate(index: currentIndex, newDate: currentPhotoDate))
        }
    }
    
    @objc func typeClick(_ sender: Any){
        guard interactionEnabled else { return }
        
        domainManager.assignPhotoDomain.actions.accept(.ShowTypeDialog(index: currentIndex))
    }
    
    @IBAction func savePhotoClick(_ sender: Any) {
        self.view.makeToast(NSLocalizedString("savingPhoto", comment: ""))
        domainManager.assignPhotoDomain.actions.accept(.Save(index: currentIndex))
    }
    
    @IBAction func skipPhotoClick(_ sender: Any) {
        domainManager.assignPhotoDomain.actions.accept(.Skip(index: currentIndex))
    }
}
