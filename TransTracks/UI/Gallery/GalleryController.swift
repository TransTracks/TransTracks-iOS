//
//  GalleryController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 7/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
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
import UIKit

class GalleryController: BackgroundGradientViewController {
    
    //MARK: Constants
    
    private static let GRID_SPAN: CGFloat = 3
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    var type: PhotoType!
    var initialEpochDay: Int!
    
    private var resultsDisposable: Disposable?
    private var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var sections: [GallerySection] = []
    
    private var selectionMode: Bool = false
    private var selection: [Photo] = []
    
    //MARK: Outlets
    
    //Strong references on purpose
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIStackView!
    @IBOutlet weak var emptyAddButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var adViewHolder: AdContainerView!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch type! {
        case .face: title = NSLocalizedString("faceGallery", comment: "")
        case .body: title = NSLocalizedString("bodyGallery", comment: "")
        }
        
        updateNavItemButtonsVisibility(animate: false)
        
        adViewHolder.setupAd("ca-app-pub-4389848400124499/3054968909", rootViewController: self)
        
        resultsDisposable = domainManager.galleryDomain.results
            .do(onSubscribe: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.domainManager.galleryDomain.actions.accept(.InitialLoad(type: self.type, epochDay: self.initialEpochDay))
                }
            })
            .subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        domainManager.galleryDomain.actions.accept(.LoadGallery(type: type))
        
        let _ = viewDisposables.insert(
            domainManager.galleryDomain.results.subscribe{ result in
                guard let result = result.element else { return }
                
                switch result {
                case .Loading:
                    self.loadingIndicator.isHidden = false
                    self.loadingIndicator.startAnimating()
                    self.showEmptyView(true)
                    self.enableUI(false)
                    
                case .Loaded(let sections):
                    self.sections = sections
                    self.collectionView.reloadData()
                    self.showEmptyView(sections.isEmpty)
                    
                    self.enableUI(true)
                    self.updateNavItemButtonsVisibility()
                    
                    self.loadingIndicator.stopAnimating()
                }
            }
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let selectPhotoController = segue.destination as? SelectPhotoController {
            selectPhotoController.domainManager = domainManager
            
            if let type = sender as? PhotoType {
                selectPhotoController.type = type
            }
        } else if let photoDetailsController = segue.destination as? PhotoDetailsController {
            photoDetailsController.domainManager = domainManager
            
            if let photo = sender as? Photo {
                photoDetailsController.photoId = photo.id
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDisposables.dispose()
        viewDisposables = CompositeDisposable()
    }
    
    deinit {
        resultsDisposable?.dispose()
    }
    
    //MARK: UI helpers
    
    func addOrRemoveSelection(photo: Photo, indexPath: IndexPath){
        if selection.contains(photo) {
            selection.remove(photo)
        } else {
            selection.append(photo)
        }
        
        if selection.isEmpty {
            enableSelectionMode(false)
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func enableSelectionMode(_ enable: Bool){
        selectionMode = enable
        updateNavItemButtonsVisibility()
        collectionView.reloadData()
    }
    
    func enableUI(_ enabled: Bool){
        addButton.isEnabled = enabled
        shareButton.isEnabled = enabled
        deleteButton.isEnabled = enabled
        emptyAddButton.isEnabled = enabled
    }
    
    func showEmptyView(_ showEmptyView: Bool){
        collectionView.isHidden = showEmptyView
        emptyView.isHidden = !showEmptyView
    }
    
    private func updateNavItemButtonsVisibility(animate: Bool = true){
        if selectionMode {
            navigationItem.setRightBarButtonItems([deleteButton, shareButton], animated: animate)
        } else {
            navigationItem.setRightBarButtonItems([shareButton, addButton], animated: animate)
        }
    }
    
    //MARK: Data helper
    
    func getPhoto(_ indexPath: IndexPath) -> Photo {
        return sections[indexPath.section].photos[indexPath.item]
    }
    
    //MARK: Button handling
    
    @IBAction func addClick(_ sender: Any) {
        
        switch PHPhotoLibrary.authorizationStatus(){
        case .authorized:
            performSegue(withIdentifier: "SelectPhoto", sender: type)
            
        case .notDetermined:
            //This case means the user is prompted for the first time for allowing acess to photos
            Assets.requestAccess { [unowned self] status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "SelectPhoto", sender: self.type)
                    }
                }
            }
            
        case .denied, .restricted:
            /// User has denied the current app to access the photos
            let alert = UIAlertController(style: .alert, title: NSLocalizedString("permissionDenied", comment: ""), message: NSLocalizedString("permissionDeniedPhotosMessage", comment: ""))
            alert.addAction(title: NSLocalizedString("settings", comment: ""), style: .default) { action in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            alert.addAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel) { [unowned self] action in
                self.alertController?.dismiss(animated: true)
            }
            alert.show()
            break;
        }
    }
    
    @IBAction func shareClick(_ sender: Any) {
        if selectionMode {
            var imagesToShare: [UIImage] = []
            
            for photo in selection {
                if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath), let image = UIImage(contentsOfFile: fileUrl.path) {
                    imagesToShare.append(image)
                }
            }
            
            let activityViewController = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            self.present(activityViewController, animated: true, completion: nil)
            enableSelectionMode(false)
            self.selection.removeAll()
        } else {
            enableSelectionMode(true)
        }
    }
    
    @IBAction func deleteClick(_ sender: Any) {
        guard selectionMode else { return }
        
        if selection.isEmpty {
            enableSelectionMode(false)
        } else {
            let alert = UIAlertController(style: .alert, title: NSLocalizedString("areYouSure", comment: ""), message: NSLocalizedString("deleteWarningMessage", comment: ""))
            alert.addAction(UIAlertAction(title:  NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { [unowned self] _ in
                self.alertController?.dismiss(animated: true)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { [unowned self] _ in
                for photo in self.selection {
                    if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath) {
                        let _ = FileUtil.deleteFile(file: fileUrl)
                    }
                    
                    self.domainManager.dataController.backgroundContext.delete(photo)
                }
                try? self.domainManager.dataController.backgroundContext.save()
                
                self.enableSelectionMode(false)
                self.selection.removeAll()
                self.domainManager.galleryDomain.actions.accept(.LoadGallery(type: self.type))
            }))
            alert.show()
        }
    }
    
    @IBAction func emptyAddClick(_ sender: Any) {
        addClick(sender)
    }
}

class GallerySection {
    let epochDay: Int64
    var photos: [Photo] = []
    
    init(epochDay: Int64){
        self.epochDay = epochDay
    }
}

extension GalleryController : UICollectionViewDelegate {
    //Long press
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        if !selectionMode {
           enableSelectionMode(true)
        }
        
        addOrRemoveSelection(photo: getPhoto(indexPath), indexPath: indexPath)
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        //Should be false to support long press
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        //No-op to support long press
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectionMode {
            addOrRemoveSelection(photo: getPhoto(indexPath), indexPath: indexPath)
        } else {
            performSegue(withIdentifier: "PhotoDetails", sender: getPhoto(indexPath))
        }
    }
}

extension GalleryController : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "GallerySectionTitle", for: indexPath) as! GallerySectionTitle
        header.label.text = Date.ofEpochDay(sections[indexPath.section].epochDay).toFullDateString()
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = getPhoto(indexPath)
        
        if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath) {
            cell.imageView.image = UIImage(contentsOfFile: fileUrl.path)
        } else {
            cell.imageView.image = nil
        }
        
        cell.selection.isHidden = !selectionMode
        
        if selectionMode {
            let imageName:String
            if selection.contains(photo) {
                imageName = "selected"
            } else {
                imageName = "unselected"
            }
            
            cell.selection.image = UIImage(named: imageName)
        }
        
        return cell
    }
}

extension GalleryController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGFloat = view.bounds.width / GalleryController.GRID_SPAN - 6
        return CGSize(width: size, height: size)
    }
}
