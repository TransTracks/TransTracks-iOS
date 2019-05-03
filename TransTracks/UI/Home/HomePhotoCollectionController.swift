//
//  HomePhotoCollectionController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 2/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import RxCocoa
import RxSwift
import RxSwiftExt
import UIKit

enum HomePhotoCollectionEvent {
    case AddPhoto(date: Date, type: PhotoType)
    case ImageClick(photoId: UUID)
}

class HomePhotoCollectionController: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //MARK: Constants
    
    private static let MIN_INSET : CGFloat = 16
    
    //MARK: Properties
    
    private let date: Date
    private let type: PhotoType
    private weak var eventRelay: PublishRelay<HomePhotoCollectionEvent>?
    
    private var photos: [Photo] = []
    
    //MARK: Lifecycle
    
    init(date: Date, type: PhotoType, eventRelay: PublishRelay<HomePhotoCollectionEvent>, dataController: DataController){
        self.date = date
        self.type = type
        self.eventRelay = eventRelay
        
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "\(Photo.FIELD_EPOCH_DAY) = %d AND \(Photo.FIELD_TYPE) = %d", date.toEpochDay(), type.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: Photo.FIELD_TIMESTAMP, ascending: false)]
        
        do {
            photos = try dataController.backgroundContext.fetch(request)
        } catch {
            print(error)
        }
    }
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            return addPhotoCell(collectionView, indexPath)
        } else {
            return photoCell(collectionView, indexPath)
        }
    }
    
    func addPhotoCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCell", for: indexPath)
    }
    
    func photoCell(_ collectionView: UICollectionView, _ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = photos[indexPath.item - 1]

        if let filePath = photo.filePath, let fileUrl = FileUtil.getFullImagePath(filename: filePath) {
            cell.imageView.image = UIImage(contentsOfFile: fileUrl.path)
        } else {
            cell.imageView.image = nil
        }
        
        cell.selection.isHidden = true
        
        return cell
    }
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            eventRelay?.accept(.AddPhoto(date: date, type: type))
        } else {
            if let photoId = photos[indexPath.item - 1].id {
                eventRelay?.accept(.ImageClick(photoId: photoId))
            }
        }
    }
    
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let itemWidth: CGFloat = self.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: section)).width
        let itemCount: CGFloat = CGFloat(self.collectionView(collectionView, numberOfItemsInSection: section))
        let minimumLineSpacing: CGFloat = (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
        
        var horizontalInset = (collectionView.width - (itemWidth * itemCount) - (minimumLineSpacing * (itemCount - 1))) / 2
        
        if horizontalInset < HomePhotoCollectionController.MIN_INSET {
            horizontalInset = HomePhotoCollectionController.MIN_INSET
        }
        
        return UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size: CGFloat = collectionView.bounds.height - 6
        return CGSize(width: size, height: size)
    }
}
