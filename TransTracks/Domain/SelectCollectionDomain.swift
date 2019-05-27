//
//  SelectCollectionDomain.swift
//  TransTracks
//
//  Created by Cassie Wilson on 27/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Photos
import RxCocoa
import RxSwift
import RxSwiftExt

enum SelectCollectionAction {
    case LoadCollections
    case CollectionsUpdated
}

enum SelectCollectionResult {
    case Loading
    case Loaded(collections: [(PHAssetCollection, Int)])
}

class SelectCollectionDomain {
    let actions: PublishRelay<SelectCollectionAction> = PublishRelay()
    var results: Observable<SelectCollectionResult>!
    
    private var albums: [(PHAssetCollection, Int)] = []
    private var smartAlbums: [(PHAssetCollection, Int)] = []
    
    init() {
        results = actions
            .startWith(.LoadCollections)
            .apply(selectCollectionActionsToResults())
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .startWith(.Loading)
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
    
    func selectCollectionActionsToResults() -> ObservableTransformer<SelectCollectionAction, SelectCollectionResult> {
        func getLoaded() -> SelectCollectionResult{
            var mergedCollections: [(PHAssetCollection, Int)] = []
            mergedCollections.append(albums)
            mergedCollections.append(smartAlbums)
            
            mergedCollections.sort{ $0.0.localizedTitle < $1.0.localizedTitle }
            
            return .Loaded(collections: mergedCollections)
        }
        
        return { actions in
            actions.map{ action in
                switch(action){
                case .LoadCollections:
                    let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
                    self.albums.removeAll()
                    albumResult.enumerateObjects{collection, _, _ in
                        self.albums.append((collection, -1))
                        self.getAssetCount(collection, isSmartAlbum: false)
                    }
                    
                    let smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
                    self.smartAlbums.removeAll()
                    smartAlbumResult.enumerateObjects{collection, _, _ in
                        self.smartAlbums.append((collection, -1))
                        self.getAssetCount(collection, isSmartAlbum: true)
                    }
                    
                    return getLoaded()
                    
                case .CollectionsUpdated:
                    return getLoaded()
                }
            }
        }
    }
    
    func getAssetCount(_ collection: PHAssetCollection, isSmartAlbum: Bool){
        Assets.fetch(in: collection){ results in
            switch results {
            case .success(let response):
                let index: Int
                
                if isSmartAlbum {
                    index = self.smartAlbums.firstIndex{ (aCollection, _) in return collection == aCollection } ?? -1
                } else {
                    index = self.albums.firstIndex{ (aCollection, _) in return collection == aCollection } ?? -1
                }
                
                guard index >= 0 else { return }
                
                if response.count < 1 {
                    if isSmartAlbum {
                        self.smartAlbums.remove(at: index)
                    } else {
                        self.albums.remove(at: index)
                    }
                } else {
                    if isSmartAlbum {
                        self.smartAlbums[index] = (collection, response.count)
                    } else {
                        self.albums[index] = (collection, response.count)
                    }
                }
                
                self.actions.accept(.CollectionsUpdated)
                
            case .error(let error):
                print(error)
            }
        }
    }
}
