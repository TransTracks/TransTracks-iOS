//
//  ViewController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 6/11/18.
//  Copyright © 2018 TransTracks. All rights reserved.
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

class HomeViewController: BackgroundGradientViewController {

    //MARK: Properties
    
    var domainManager: DomainManager!
    
    var resultsDisposable: Disposable?
    var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var eventRelay: PublishRelay<HomePhotoCollectionEvent> = PublishRelay()
    
    private var facePhotosController: HomePhotoCollectionController? = nil
    private var bodyPhotosController: HomePhotoCollectionController? = nil
    
    //MARK: Outlets
    
    @IBOutlet weak var day: UILabel!
    
    @IBOutlet weak var previousRecord: UIButton!
    @IBOutlet weak var nextRecord: UIButton!
    
    @IBOutlet weak var startDate: UILabel!
    @IBOutlet weak var currentDate: UILabel!
    
    @IBOutlet weak var milestones: UIButton!
    
    @IBOutlet weak var faceCollection: UICollectionView!
    @IBOutlet weak var bodyCollection: UICollectionView!
    
    @IBOutlet weak var adViewHolder: AdContainerView!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsDisposable = domainManager.homeDomain.results.subscribe()
        
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let adUnitId = (config["ad_ids"] as? NSDictionary)?["home"] as? String {
            adViewHolder.setupAd(adUnitId, rootViewController: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        domainManager.homeDomain.actions.accept(.ReloadDay)
        
        if UserDefaultsUtil.showWelcome() {
            performSegue(withIdentifier: "Welcome", sender: nil)
            UserDefaultsUtil.setShowWelcome(false)
        }
        
        let _ = viewDisposables.insert(
            domainManager.homeDomain.results.subscribe{result in
                guard let result = result.element else { return }
            
                switch(result){
                case HomeResult.Loading(_):
                    break
                    
                case HomeResult.Loaded(let dayString, let showPreviousRecord, let showNextRecord, let startDate, let currentDate, let hasMilestones, let showAds):
                    self.day.text = dayString.uppercased()
                    
                    self.previousRecord.isHidden = !showPreviousRecord
                    self.nextRecord.isHidden = !showNextRecord
                    
                    self.startDate.text = String(format: NSLocalizedString("startDate", comment: ""), startDate.toFullDateString())
                    self.currentDate.text = String(format: NSLocalizedString("currentDate", comment: ""), currentDate.toFullDateString())
                    
                    self.milestones.imageView?.image = UIImage(named: hasMilestones ? "milestone_selected" : "milestone_unselected")
                    
                    self.facePhotosController = HomePhotoCollectionController(date: currentDate, type: .face, eventRelay: self.eventRelay, dataController: self.domainManager.dataController)
                    self.bind(collectionView: self.faceCollection, controller: self.facePhotosController!)
                    
                    self.bodyPhotosController = HomePhotoCollectionController(date: currentDate, type: .body, eventRelay: self.eventRelay, dataController: self.domainManager.dataController)
                    self.bind(collectionView: self.bodyCollection, controller: self.bodyPhotosController!)
                    
                    self.adViewHolder.isHidden = !showAds
                }
            }
        )
        
        let _ = viewDisposables.insert(
            domainManager.homeDomain.viewEffects.subscribe{ effect in
                guard let effect = effect.element else { return }
                
                switch effect {
                case .ShowMilestones(let day):
                    self.performSegue(withIdentifier: "Milestones", sender: day)
                    
                case .OpenGallery(let day, let type):
                    var args: [SegueKey: Any] = [:]
                    args[SegueKey.epochDay] = day.toEpochDay()
                    args[SegueKey.type] = type
                    
                    self.performSegue(withIdentifier: "Gallery", sender: args)
                }
            }
        )
        
        let _ = viewDisposables.insert(
            eventRelay.subscribe { event in
                guard let event = event.element else { return }
                
                switch event {
                case .AddPhoto(let date, let type):
                    var args: [SegueKey: Any] = [:]
                    args[SegueKey.epochDay] = date.toEpochDay()
                    args[SegueKey.type] = type
                    
                    self.addPhoto(args)
                    
                case .ImageClick(let photoId):
                    self.performSegue(withIdentifier: "PhotoDetails", sender: photoId)
                }
            }
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let selectPhotoController = segue.destination as? SelectPhotoController {
            selectPhotoController.domainManager = domainManager
            
            if let args = sender as? [SegueKey: Any] {
                args.forEach{ key, value in
                    switch key {
                    case .epochDay:
                        if let epochDay = value as? Int {
                            selectPhotoController.epochDay = epochDay
                        }
                        
                    case .type:
                        if let type = value as? PhotoType {
                            selectPhotoController.type = type
                        }
                        
                    default:
                        break
                    }
                }
            }
        } else if let photoDetailsController = segue.destination as? PhotoDetailsController {
            photoDetailsController.domainManager = domainManager
            
            if let photoId = sender as? UUID {
                photoDetailsController.photoId = photoId
            }
        } else if let galleryController = segue.destination as? GalleryController {
            galleryController.domainManager = domainManager
            
            if let args = sender as? [SegueKey: Any] {
                args.forEach{ key, value in
                    switch key {
                    case .epochDay:
                        if let epochDay = value as? Int {
                            galleryController.initialEpochDay = epochDay
                        }
                        
                    case .type:
                        if let type = value as? PhotoType {
                            galleryController.type = type
                        }
                        
                    default:
                        break
                    }
                }
            }
        } else if let milestonesController = segue.destination as? MilestonesController {
            milestonesController.domainManager = domainManager
            
            if let day = sender as? Date {
                milestonesController.initialEpochDay = day.toEpochDay()
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
    
    //MARK: UI Helper
    
    private func bind(collectionView: UICollectionView, controller: HomePhotoCollectionController){
        collectionView.dataSource = controller
        collectionView.delegate = controller
    }

    //MARK: Button handling
    
    @IBAction func addPhoto(_ sender: Any) {
        switch PHPhotoLibrary.authorizationStatus(){
        case .authorized:
            performSegue(withIdentifier: "SelectPhoto", sender: sender)
            
        case .notDetermined:
            //This case means the user is prompted for the first time for allowing acess to photos
            Assets.requestAccess { [unowned self] status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "SelectPhoto", sender: sender)
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
    
    @IBAction func showPreviousRecord(_ sender: Any) {
        domainManager.homeDomain.actions.accept(.PreviousDay)
    }
    
    @IBAction func showNextRecord(_ sender: Any) {
        domainManager.homeDomain.actions.accept(.NextDay)
    }
    
    @IBAction func milestonesClick(_ sender: Any) {
        domainManager.homeDomain.actions.accept(.ShowMilestones)
    }
    
    @IBAction func showFaceGallery(_ sender: Any) {
        domainManager.homeDomain.actions.accept(.OpenGallery(type: .face))
    }
    
    @IBAction func showBodyGallery(_ sender: Any) {
        domainManager.homeDomain.actions.accept(.OpenGallery(type: .body))
    }
    
    private enum SegueKey {
        case epochDay, type, photoId
    }
}

