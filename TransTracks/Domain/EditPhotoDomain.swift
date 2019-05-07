//
//  EditPhotoDomain.swift
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

import CoreData
import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt

enum EditPhotoAction {
    case InitialData(photo: Photo)
    
    case ShowDateDialog
    case ChangeDate(newDate: Date)
    
    case ShowTypeDialog
    case ChangeType(newType: PhotoType)
    
    case Save
}

enum EditPhotoResult {
    case Display(image: URL?, date: Date, type: PhotoType)
    case Saving
}

enum EditPhotoViewEffect {
    case ShowDateDialog(currentDate: Date)
    case ShowTypeDialog(currentType: PhotoType)
    
    case SaveSuccess
    case SaveFailure
}

class EditPhotoDomain {
    let actions: PublishRelay<EditPhotoAction> = PublishRelay()
    private let viewEffectRelay: PublishRelay<EditPhotoViewEffect> = PublishRelay()
    let viewEffects: Observable<EditPhotoViewEffect>
    var results: Observable<EditPhotoResult>!
    
    private var photo: Photo!
    private var date: Date!
    private var type: PhotoType!
    
    init() {
        viewEffects = viewEffectRelay.asObservable()
        results = actions
            .apply(editPhotoActionsToResults())
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
    
    func editPhotoActionsToResults() -> ObservableTransformer<EditPhotoAction, EditPhotoResult> {
        func getImageUrl(_ photo: Photo) -> URL? {
            if let filePath = photo.filePath {
                return FileUtil.getFullImagePath(filename: filePath)
            }
            
            return nil
        }
        
        func getObservableFromAction(action: EditPhotoAction) -> Observable<EditPhotoResult> {
            switch action {
            case .InitialData(let photo):
                self.photo = photo
                date = Date.ofEpochDay(photo.epochDay)
                type = PhotoType(rawValue: Int(photo.type))!
                return Observable.just(.Display(image: getImageUrl(photo), date: date, type: type))

            case .ShowDateDialog:
                viewEffectRelay.accept(.ShowDateDialog(currentDate: date))
                return Observable.just(.Display(image: getImageUrl(photo), date: date, type: type))

            case .ChangeDate(let newDate):
                date = newDate
                return Observable.just(.Display(image: getImageUrl(photo), date: date, type: type))

            case .ShowTypeDialog:
                viewEffectRelay.accept(.ShowTypeDialog(currentType: type))
                return Observable.just(.Display(image: getImageUrl(photo), date: date, type: type))

            case .ChangeType(let newType):
                type = newType
                return Observable.just(.Display(image: getImageUrl(photo), date: date, type: type))

            case .Save:
                return Observable.just(EditPhotoResult.Saving).map{ _ in
                    self.photo.epochDay = Int64(self.date.toEpochDay())
                    self.photo.type = Int16(self.type.rawValue)

                    do {
                        try self.photo.managedObjectContext!.save()

                        self.viewEffectRelay.accept(.SaveSuccess)
                        return EditPhotoResult.Saving
                    } catch {
                        self.viewEffectRelay.accept(.SaveFailure)
                        return EditPhotoResult.Display(image: getImageUrl(self.photo), date: self.date, type: self.type)
                    }
                }
                .startWith(EditPhotoResult.Saving)
            }
        }
        
        return { actions in
            return actions.flatMapLatest{
                return getObservableFromAction(action: $0)
            }
        }
    }
}
