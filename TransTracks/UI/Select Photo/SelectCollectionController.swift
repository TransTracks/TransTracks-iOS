//
//  SelectCollectionController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 20/5/19.
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

class SelectCollectionController: BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    
    var epochDay: Int?
    var type: PhotoType = PhotoType.face
    
    private var resultsDisposable: Disposable?
    private var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var collections: [(PHAssetCollection, Int)] = []
    
    //MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsDisposable = domainManager.homeDomain.results.subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        domainManager.selectCollectionDomain.actions.accept(.LoadCollections)
        
        let _ = viewDisposables.insert(
            domainManager.selectCollectionDomain.results.subscribe{ result in
                guard let result = result.element else { return }
                
                switch result {
                case .Loading:
                    break
                    
                case .Loaded(let collections):
                    self.collections.removeAll()
                    self.collections.append(collections)
                    
                    self.tableView.reloadData()
                    break
                }
            }
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let selectPhotoController = segue.destination as? SelectPhotoController {
            selectPhotoController.domainManager = domainManager
            selectPhotoController.epochDay = epochDay
            selectPhotoController.type = type
            
            if let collection = sender as? PHAssetCollection {
                selectPhotoController.collection = collection
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
}

extension SelectCollectionController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (collection, _) = collections[indexPath.row]
        
        performSegue(withIdentifier: "SelectCollection", sender: collection)
    }
}

extension SelectCollectionController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCollectionCell", for: indexPath)
        let (collection, photoCount) = collections[indexPath.row]
        
        cell.textLabel?.text = collection.localizedTitle ?? NSLocalizedString("untitledAlbum", comment: "")
        
        let detailText: String
        if photoCount >= 0 {
            detailText = "\(photoCount)"
        } else {
            if collection.estimatedAssetCount == Int.max {
                 detailText = "0"
            } else {
                detailText = "\(collection.estimatedAssetCount)"
            }
        }
        cell.detailTextLabel?.text = detailText
        
        return cell
    }
}
