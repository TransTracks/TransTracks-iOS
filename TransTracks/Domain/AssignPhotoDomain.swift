//
//  AssignPhotoDomain.swift
//  TransTracks
//
//  Created by Cassie Wilson on 30/4/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import Foundation
import Photos
import RxCocoa
import RxSwift
import RxSwiftExt

enum AssignPhotoAction {
    case InitialData(photos: [PHAsset]?, image: UIImage?, epochDay: Int?, type: PhotoType)
    case LoadImage(index: Int)
    
    case ShowDateDialog(index: Int)
    case ChangeDate(index: Int, newDate: Date)
    
    case ShowTypeDialog(index: Int)
    case ChangeType(index: Int, newType: PhotoType)
    
    case Save(index: Int)
    case SaveSuccess(index: Int)
    case SaveFailure(index: Int)
    
    case Skip(index: Int)
}

enum AssignPhotoResult {
    case Loading(index: Int, count: Int)
    case Display(asset: PHAsset?, image: UIImage?, date: Date, photoDate: Date?, type: PhotoType, index: Int, count: Int)
    case SavingImage(asset: PHAsset?, image: UIImage?, date: Date, photoDate: Date?, type: PhotoType, index: Int, count: Int)
}

enum AssignPhotoViewEffect {
    case ShowDateDialog(date: Date)
    case ShowTypeDialog(type: PhotoType)
    case ShowSaveSuccess
    case ShowSaveError
    case ShowSkipMessage
    case CompletedAssigning
}

class AssignPhotoDomain {
    private var image: UIImage? = nil
    private var photos: [PHAsset]? = nil
    private var type: PhotoType = PhotoType.face
    private var epochDay: Int? = nil
    
    private var date: Date = Date().startOfDay()
    private var photoDate: Date? = nil
    
    let actions: PublishRelay<AssignPhotoAction> = PublishRelay()
    
    private let viewEffectRelay: PublishRelay<AssignPhotoViewEffect> = PublishRelay()
    let viewEffects: Observable<AssignPhotoViewEffect>
    
    var results: Observable<AssignPhotoResult>!
    
    init(dataController: DataController) {
        viewEffects = viewEffectRelay.asObservable()
        results = actions
            .apply(assignPhotoActionsToResults(dataController))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
    
    func assignPhotoActionsToResults(_ dataController: DataController) -> ObservableTransformer<AssignPhotoAction, AssignPhotoResult> {
        func getObservableFromAction(action: AssignPhotoAction) -> Observable<AssignPhotoResult> {
            switch(action){
            case .InitialData(let photos, let image, let epochDay, let type):
                self.image = image
                self.photos = photos
                self.type = type
                self.epochDay = epochDay
                
                if image != nil {
                    return Observable.just(loadImage(0)).startWith(.Loading(index: 0, count: 1))
                } else if let photos = photos {
                    return Observable.just(loadImage(0)).startWith(.Loading(index: 0, count: photos.count))
                } else {
                    fatalError("Image or Photos needs to be set")
                }
                
            case .LoadImage(let index):
                return Observable.just(loadImage(index))
                
            case .ShowDateDialog(let index):
                viewEffectRelay.accept(.ShowDateDialog(date: date))
                return Observable.just(.Display(asset: photos?[index], image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .ChangeDate(let index, let newDate):
                date = newDate
                return Observable.just(.Display(asset: photos?[index], image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .ShowTypeDialog(let index):
                viewEffectRelay.accept(.ShowTypeDialog(type: type))
                return Observable.just(.Display(asset: photos?[index], image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .ChangeType(let index, let newType):
                type = newType
                return Observable.just(.Display(asset: photos?[index], image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .Save(let index):
                var asset:PHAsset? = photos?[index]
                
                let failure = { self.actions.accept(.SaveFailure(index: index)) }
                
                let completion: (_ imageURL: URL) -> Void = { imageURL in
                    let photo = Photo(context: dataController.backgroundContext)
                    photo.id = UUID()
                    photo.epochDay = Int64(exactly: self.date.toEpochDay())!
                    photo.filePath = imageURL.lastPathComponent
                    photo.timestamp = Date()
                    photo.type = Int16(exactly: self.type.rawValue)!
                    
                    do {
                        try dataController.backgroundContext.save()
                        self.actions.accept(.SaveSuccess(index: index))
                    } catch {
                        print(error)
                        self.actions.accept(.SaveFailure(index: index))
                    }
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if let image = self.image {
                        requestImageToSave(image: image, failure: failure, completion: completion)
                    } else if let asset = asset {
                        requestImageToSave(asset: asset, failure: failure, completion: completion)
                    } else {
                        fatalError("Image or Photos needs to be set")
                    }
                }
                
                return Observable.just(AssignPhotoResult.SavingImage(asset: asset, image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .SaveSuccess(let index):
                viewEffectRelay.accept(.ShowSaveSuccess)
                return Observable.just(moveToNext(index))
                
            case .SaveFailure(let index):
                viewEffectRelay.accept(.ShowSaveError)
                return Observable.just(.Display(asset: photos?[index], image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1))
                
            case .Skip(let index):
                self.viewEffectRelay.accept(.ShowSkipMessage)
                return Observable.just(moveToNext(index))
            }
        }
        
        func loadImage(_ index: Int) -> AssignPhotoResult {
            let asset = photos?[index]
            
            photoDate = nil
            
            if image != nil {
                photoDate = Date()
            } else if let asset = asset {
                if let creationDate = asset.creationDate{
                    photoDate = creationDate
                } else if let modificationDate = asset.modificationDate{
                    photoDate = modificationDate
                }
            } else {
                fatalError("Image or Photos needs to be set")
            }
            
            if let epochDay = epochDay {
                date = Date.ofEpochDay(epochDay)
            } else if let photoDate = photoDate{
                date = photoDate
            } else {
                date = Date().startOfDay()
            }
            
            return .Display(asset: asset, image: image, date: date, photoDate: photoDate, type: type, index: index, count: photos?.count ?? 1)
        }
        
        func moveToNext(_ index: Int) -> AssignPhotoResult {
            let count: Int = self.photos?.count ?? 1
            
            if index + 1 >= count {
                self.viewEffectRelay.accept(.CompletedAssigning)
                return AssignPhotoResult.Loading(index: index, count: self.photos?.count ?? 1)
            } else {
                return AssignPhotoResult.Display(asset: self.photos?[index + 1], image: image, date: self.date, photoDate: self.photoDate, type: self.type, index: index + 1, count: self.photos?.count ?? 1)
            }
        }
        
        func requestImageToSave(asset: PHAsset, failure: @escaping () -> Void, completion: @escaping (_ imageURL: URL) -> Void){
            let imageManager = PHImageManager.default()
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isSynchronous = false
            requestOptions.isNetworkAccessAllowed = true
            
            imageManager.requestImageData(for: asset, options: requestOptions){ imageData, dataUTI, orientation, info in
                if let imageData = imageData, let newFileUrl = FileUtil.getNewImageFileURL(photoDate: self.date) {
                    do {
                        try imageData.write(to: newFileUrl)
                        completion(newFileUrl)
                    } catch {
                        print(error)
                        failure()
                    }
                }
            }
        }
        
        func requestImageToSave(image: UIImage, failure: @escaping () -> Void, completion: @escaping (_ imageURL: URL) -> Void){
            if let imageData = image.jpegData(compressionQuality: 1), let newFileUrl = FileUtil.getNewImageFileURL(photoDate: self.date){
                do {
                    try imageData.write(to: newFileUrl)
                    completion(newFileUrl)
                } catch {
                    print(error)
                    failure()
                }
            } else {
                failure()
            }
        }
        
        return { actions in
            return actions.flatMapLatest{
                return getObservableFromAction(action: $0)
            }
        }
    }
}
