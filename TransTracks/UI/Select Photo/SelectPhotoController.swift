//
//  SelectPhotoController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 3/4/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Photos
import UIKit

class SelectPhotoController: BackgroundGradientCollectionViewController {
    
    //MARK: Properties
    var domainManager: DomainManager!
    
    var epochDay: Int?
    var type: PhotoType = PhotoType.face
    
    private let hasCamera: Bool = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    private var assets: [PHAsset] = []
    
    private var selectionMode: Bool = false
    private var selection: [PHAsset] = []
    
    private var imagePicker: UIImagePickerController?
    
    //MARK: Outlets
    
    //Strong reference on purpose
    @IBOutlet var saveToApp: UIBarButtonItem!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePhotos()
        updateSaveButtonVisibility(animate: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let assignPhotoController = segue.destination as? AssignPhotoController {
            assignPhotoController.domainManager = domainManager
            
            if let args = sender as? [SegueKey:Any] {
                args.forEach{ key, value in
                    switch key {
                    case .photos:
                        guard let photos = value as? [PHAsset] else { fatalError("photos arg is required to segue to AssignPhotoController") }
                        assignPhotoController.photos = photos
                        
                    case .epochDay:
                        if let epochDay = value as? Int {
                            assignPhotoController.epochDay = epochDay
                        }
                        
                    case .type:
                        if let type = value as? PhotoType {
                            assignPhotoController.type = type
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Data helper functions

    private func checkStatus(completionHandler: @escaping ([PHAsset]) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            /// Authorization granted by user for this app.
            DispatchQueue.main.async {
                Assets.fetch { [unowned self] result in
                    switch result {
                    case .success(let assets):
                        completionHandler(assets)
                        
                    case .error(let error):
                        let alert = UIAlertController(style: .alert, title: NSLocalizedString("error", comment: ""), message: error.localizedDescription)
                        alert.addAction(title: NSLocalizedString("ok", comment: "")) { [unowned self] action in
                            self.dismiss(animated: true, completion: nil)
                        }
                        alert.show()
                    }
                }
            }
            
        case .denied, .restricted, .notDetermined:
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func getAsset(_ indexPath: IndexPath) -> PHAsset {
        var index = indexPath.item
        
        if hasCamera {
            index -= 1
        }
        
        return assets[index]
    }
    
    private func updatePhotos(){
        checkStatus { [unowned self] assets in
            self.assets.removeAll()
            self.assets.append(contentsOf: assets)
            self.collectionView.reloadData()
        }
    }
    
    //MARK: UI helper functions
    
    func addOrRemoveSelection(asset: PHAsset, indexPath: IndexPath){
        if selection.contains(asset) {
            selection.remove(asset)
        } else {
            selection.append(asset)
        }
        
        if selection.isEmpty {
            selectionMode = false
            updateSaveButtonVisibility()
            collectionView.reloadData()
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    private func segueToAssignPhotos(_ assets: [PHAsset]){
        guard !assets.isEmpty else { return }
        
        var args: [SegueKey:Any] = [:]
        args[.photos] = assets
        args[.type] = type
        
        if let epochDay = epochDay {
            args[.epochDay] = epochDay
        }
        
        performSegue(withIdentifier: "AssignPhoto", sender: args)
    }
    
    private func takePhoto(){
        imagePicker = UIImagePickerController()
        imagePicker!.delegate = self
        imagePicker!.sourceType = .camera
        
        present(imagePicker!, animated: true, completion: nil)
    }
    
    private func updateSaveButtonVisibility(animate: Bool = true){
        if selectionMode {
            navigationItem.setRightBarButton(saveToApp, animated: animate)
        } else {
            navigationItem.setRightBarButton(nil, animated: animate)
        }
    }
    
    //MARK: Button handling
    
    @IBAction func saveToAppClick(_ sender: Any) {
        guard !selection.isEmpty else { return }
        
        self.segueToAssignPhotos(selection)
    }
    
    //MARK: UICollectionViewDelegate
    
    //Long press
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if !selectionMode {
            selectionMode = true
            updateSaveButtonVisibility()
            collectionView.reloadData()
        }
        
        let asset = getAsset(indexPath)
        addOrRemoveSelection(asset: asset, indexPath: indexPath)
        
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        //Should be false to support long press
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        //No-op to support long press
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if hasCamera && indexPath.item == 0 {
            takePhoto()
        } else if selectionMode {
            let asset = getAsset(indexPath)
            addOrRemoveSelection(asset: asset, indexPath: indexPath)
        } else {
            let asset = getAsset(indexPath)
            self.segueToAssignPhotos([asset])
        }
    }
    
    //MARK: CollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let assetsCount = assets.count
        
        if hasCamera {
            return assetsCount + 1
        } else {
            return assetsCount
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if hasCamera && indexPath.item == 0 {
            return addPhotoCell(collectionView, indexPath)
        } else{
            return photoCell(collectionView, indexPath)
        }
    }
    
    func addPhotoCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCell", for: indexPath)
    }
    
    func photoCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let asset = getAsset(indexPath)
        Assets.resolve(asset: asset, size: cell.imageView.bounds.size) { newPhoto in
            cell.imageView.image = newPhoto
        }
        
        cell.selection.isHidden = !selectionMode
        
        if selectionMode {
            let imageName:String
            if selection.contains(asset) {
                imageName = "selected"
            } else {
                imageName = "unselected"
            }
            
            cell.selection.image = UIImage(named: imageName)
        }
        
        return cell
    }
    
    //MARK: Constants
    
    private let GRID_SPAN: CGFloat = 3
    
    private enum SegueKey {
        case photos, epochDay, type
    }
}

extension SelectPhotoController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGFloat = view.bounds.width / GRID_SPAN - 6
        return CGSize(width: size, height: size)
    }
}

extension SelectPhotoController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker?.dismiss(animated: true, completion: nil)
        imagePicker = nil
        
        
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
             segueToAssignPhotos([asset])
        }
    }
}
