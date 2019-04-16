//
//  AssignPhotoController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 16/4/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class AssignPhotoController : BackgroundGradientViewController {
    
    //MARK: Properties
    
    var photos: [UIImage]!
    var epochDay: Int?
    var type: PhotoType = PhotoType.face
    
    //MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var usePhotoDate: UIButton!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var skipButton: UIButton!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabelTapRecognizers()
        
        skipButton.isHidden = photos.count == 1
        
        loadImage(0)
    }
    
    //MARK: UI Helpers
    private func loadImage(_ index: Int){
        imageView.image = photos[index]
        
        //TODO the rest of the setup here
    }
    
    private func setupLabelTapRecognizers(){
        let dateTap = UITapGestureRecognizer(target: self, action: #selector(dateClick(_:)))
        dateLabel.addGestureRecognizer(dateTap)
        
        let typeTap = UITapGestureRecognizer(target: self, action: #selector(typeClick(_:)))
        typeLabel.addGestureRecognizer(typeTap)
    }
    
    //MARK: Button handling
    
    @objc func dateClick(_ sender: Any){
        
    }
    
    @IBAction func usePhotoDateClick(_ sender: Any) {
    }
    
    @objc func typeClick(_ sender: Any){
    
    }
    
    @IBAction func savePhotoClick(_ sender: Any) {
    }
    
    @IBAction func skipPhotoClick(_ sender: Any) {
    }
}
