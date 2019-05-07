//
//  PhotoDetailsController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 3/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import UIKit

class PhotoDetailsController: BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    
    var photoId: UUID!
    
    private var photo: Photo?
    
    //MARK: Outlets
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailsLabel: UILabel!
    
    //MARK: Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "\(Photo.FIELD_ID) = %@", photoId as CVarArg)
        request.fetchLimit = 1
        
        var success = false
        
        do {
            photo = try domainManager.dataController.viewContext.fetch(request).first
            
            if let photo = photo {
                success = true
                
                if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath) {
                    imageView.image = UIImage(contentsOfFile: fileUrl.path)
                } else {
                    imageView.image = nil
                }
                
                let date = Date.ofEpochDay(photo.epochDay)
                let type = PhotoType.init(rawValue: Int(photo.type))!
                
                detailsLabel.text = "\(date.toFullDateString()) - \(type.getDisplayName())"
            }
        } catch {
            print(error)
        }
        
        if !success {
            //Disable buttons
            editButton.isEnabled = false
            shareButton.isEnabled = false
            deleteButton.isEnabled = false
            
            showPhotoDetailLoadingError()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "EditPhoto" {
            if photo == nil {
                showPhotoDetailLoadingError()
                return false
            }
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let editPhotoController = segue.destination as? EditPhotoController {
            editPhotoController.domainManager = domainManager
            editPhotoController.photo = photo!
        }
    }
    
    //MARK: UI helper
    
    private func showPhotoDetailLoadingError() {
        //Show alert dialog to inform the user and kick them out
        let alert = UIAlertController(style: .alert, title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("errorLoadingPhotoDetails", comment: ""))
        alert.addAction(title: NSLocalizedString("ok", comment: "")) { [weak self] action in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        alert.show()
    }
    
    //MARK: Button handling
    
    @IBAction func shareClick(_ sender: Any) {
        guard let image = imageView.image else {
            //Notify the user the image hasn't loaded correctrly
            let alert = UIAlertController(style: .alert, title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("errorLoadingPhoto", comment: ""))
            alert.addAction(title: NSLocalizedString("ok", comment: "")) { [unowned self] action in
                self.alertController?.dismiss(animated: true)
            }
            alert.show()
            
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func deleteClick(_ sender: Any) {
        guard let photo = photo else { return }
        
        let alert = UIAlertController(style: .alert, title: NSLocalizedString("areYouSure", comment: ""), message: NSLocalizedString("deleteWarningMessage", comment: ""))
        alert.addAction(UIAlertAction(title:  NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { [unowned self] _ in
            self.alertController?.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { [unowned self] _ in
            if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath) {
                let _ = FileUtil.deleteFile(file: fileUrl)
            }
            
            self.domainManager.dataController.viewContext.delete(photo)
            try? self.domainManager.dataController.viewContext.save()
            
            self.navigationController?.popToRootViewController(animated: true)
        }))
        alert.show()
    }
}
