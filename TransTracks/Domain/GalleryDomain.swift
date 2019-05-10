//
//  GalleryDomain.swift
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

import CoreData
import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt

enum GalleryAction {
    case InitialLoad(type: PhotoType, epochDay: Int)
    case LoadGallery(type: PhotoType)
}

enum GalleryResult {
    case Loading
    case Loaded(sections: [GallerySection])
}

enum GalleryViewEffect {
    case ScrollToDay(epochDay: Int)
}

class GalleryDomain {
    let actions: PublishRelay<GalleryAction> = PublishRelay()
    
    private let viewEffectRelay: PublishRelay<GalleryViewEffect> = PublishRelay()
    let viewEffects: Observable<GalleryViewEffect>
    
    var results: Observable<GalleryResult>!
    
    init(dataController: DataController){
        viewEffects = viewEffectRelay.asObservable()
        results = actions
            .apply(galleryActionsToResults(dataController, viewEffectRelay))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
}

func galleryActionsToResults(_ dataController: DataController, _ viewEffectRelay:PublishRelay<GalleryViewEffect>) -> ObservableTransformer<GalleryAction, GalleryResult> {
    func getObservableFromAction(action: GalleryAction) -> Observable<GalleryResult> {
        switch action {
        case .InitialLoad(let type, let epochDay):
            return loadingObservable(type: type, epochDay: epochDay)
        case .LoadGallery(let type):
            return loadingObservable(type: type)
        }
    }
    
    func loadingObservable(type: PhotoType, epochDay: Int? = nil) -> Observable<GalleryResult> {
        return Observable.just(GalleryResult.Loading)
            .map { _ in
                let request: NSFetchRequest<Photo> = Photo.fetchRequest()
                request.predicate = NSPredicate(format: "\(Photo.FIELD_TYPE) = %d", type.rawValue)
                request.sortDescriptors = [NSSortDescriptor(key: Photo.FIELD_EPOCH_DAY, ascending: false), NSSortDescriptor(key: Photo.FIELD_TIMESTAMP, ascending: true)]
                
                var sections: [GallerySection] = []
                
                if let photos = try? dataController.backgroundContext.fetch(request) {
                    for photo in photos {
                        var currentSection = sections.last
                        
                        if currentSection == nil || currentSection!.epochDay != photo.epochDay {
                            currentSection = GallerySection(epochDay: photo.epochDay)
                            sections.append(currentSection!)
                        }
                        
                        currentSection!.photos.append(photo)
                    }
                }
                
                if let epochDay = epochDay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                        viewEffectRelay.accept(.ScrollToDay(epochDay: epochDay))
                    }
                }
                
                return .Loaded(sections: sections)
            }
            .startWith(GalleryResult.Loading)
    }
    
    return { actions in
        actions.flatMapLatest{
            getObservableFromAction(action: $0)
        }
    }
}
