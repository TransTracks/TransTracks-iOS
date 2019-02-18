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

import GoogleMobileAds
import UIKit

class HomeViewController: BackgroundGradientViewController {

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
    
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let adUnitId = (config["ad_ids"] as? NSDictionary)?["home"] as? String {
            adViewHolder.setupAd(adUnitId, rootViewController: self)
        }
    }

    //MARK: Button handling
    
    @IBAction func addPhoto(_ sender: Any) {
    }
    
    @IBAction func showPreviousRecord(_ sender: Any) {
    }
    
    @IBAction func showNextRecord(_ sender: Any) {
    }
    
    @IBAction func showFaceGallery(_ sender: Any) {
    }
    
    @IBAction func showBodyGallery(_ sender: Any) {
    }
}

