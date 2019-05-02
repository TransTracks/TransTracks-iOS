//
//  AdView.swift
//  TransTracks
//
//  Created by Cassie Wilson on 18/2/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import GoogleMobileAds
import UIKit

class AdContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addTopBorder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addTopBorder()
    }
    
    private func addTopBorder(){
        backgroundColor = UIColor.black
        
        clipsToBounds = false
        
        let topBorder = CALayer()
        topBorder.backgroundColor = UIColor.colorFromHexString("#9FCAD9").cgColor
        topBorder.frame = CGRect(x: 0, y: -2, width: frame.width, height: 1)
        
        layer.addSublayer(topBorder)
        
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIColor.colorFromHexString("#B7E9FA").cgColor
        bottomBorder.frame = CGRect(x: 0, y: -1, width: frame.width, height: 1)
        
        layer.addSublayer(bottomBorder)
    }
    
    func setupAd(_ adUnitId: String, rootViewController: UIViewController){
        let bannerAd = GADBannerView.getAdView(adUnitId, rootViewController: rootViewController)
        
        addSubview(bannerAd)
        
        addConstraints([
            NSLayoutConstraint(item: bannerAd,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: CGFloat(1.0),
                               constant:  CGFloat(2.0)),
            NSLayoutConstraint(item: bannerAd,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .leading,
                               multiplier: CGFloat(1.0),
                               constant:  CGFloat(0.0)),
            NSLayoutConstraint(item: bannerAd,
                               attribute: .trailing,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .trailing,
                               multiplier: CGFloat(1.0),
                               constant:  CGFloat(0.0))
            ])
        
        superview?.addConstraint(NSLayoutConstraint(item: bannerAd,
                                              attribute: NSLayoutConstraint.Attribute.bottom,
                                              relatedBy: NSLayoutConstraint.Relation.equal,
                                              toItem: superview!.safeAreaLayoutGuide,
                                              attribute: NSLayoutConstraint.Attribute.bottom,
                                              multiplier: CGFloat(1.0),
                                              constant:  CGFloat(0.0)))
    }
}