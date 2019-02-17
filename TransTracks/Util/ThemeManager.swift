//
//  ThemeManager.swift
//  TransTracks
//
//  Created by Cassie Wilson on 16/2/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import UIKit

class ThemeManager {
    private static func getTheme() -> Theme {
        return UserDefaultsUtil.getTheme()
    }
    
    static func getBackgroundGradient() -> CAGradientLayer {
        let theme = getTheme()
        
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [theme.colorPrimary.cgColor, theme.colorPrimaryLight.cgColor, theme.colorAccent.cgColor]
        backgroundGradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.6), NSNumber(value: 1.0)]
        backgroundGradient.startPoint = CGPoint(x: 1.0, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.8, y: 1.0)
        
        return backgroundGradient
    }
}

enum Theme: String {
    case Pink
    case Blue
    case Purple
    case Green
    
    var colorPrimaryLight: UIColor {
        switch self {
        case .Pink: return UIColor.colorFromHexString("#ffbde4")
        case .Blue: return UIColor.colorFromHexString("#a3d3ff")
        case .Purple: return UIColor.colorFromHexString("#be9df5")
        case .Green: return UIColor.colorFromHexString("#4ecc84")
        }
    }
    
    var colorPrimary: UIColor {
        switch self {
        case .Pink: return UIColor.colorFromHexString("#E4A9CC")
        case .Blue: return UIColor.colorFromHexString("#9ECCF6")
        case .Purple: return UIColor.colorFromHexString("#977cc2")
        case .Green: return UIColor.colorFromHexString("#3A9963")
        }
    }
    
    var colorPrimaryDark: UIColor {
        switch self {
        case .Pink: return UIColor.colorFromHexString("#b0829e")
        case .Blue: return UIColor.colorFromHexString("#7ca0c2")
        case .Purple: return UIColor.colorFromHexString("#6f5b8f")
        case .Green: return UIColor.colorFromHexString("#276642")
        }
    }
    
    var colorAccent: UIColor {
        switch self {
        case .Pink: return UIColor.colorFromHexString("#9ECCF6")
        case .Blue: return UIColor.colorFromHexString("#E4A9CC")
        case .Purple: return UIColor.colorFromHexString("#9ECCF6")
        case .Green: return UIColor.colorFromHexString("#57acd4")
        }
    }
}
