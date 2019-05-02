//
//  DividerView.swift
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

import UIKit

class DividerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.clear
        
        let white = UIColor.white
        let clear = white.withAlphaComponent(0.0)
        
        let newGradient = CAGradientLayer()
        newGradient.colors = [clear.cgColor, white.cgColor, clear.cgColor]
        newGradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 1.0)]
        newGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        newGradient.endPoint = CGPoint(x: 1.0, y: 0.0)
        newGradient.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        layer.insertSublayer(newGradient, at: 0)
    }
}