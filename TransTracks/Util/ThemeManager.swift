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
        return SettingsManager.getTheme()
    }
    
    static func getBackgroundGradient(_ theme: Theme) -> CAGradientLayer {
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [theme.colorPrimary.cgColor, theme.colorPrimaryLight.cgColor, theme.colorAccent.cgColor]
        backgroundGradient.locations = [NSNumber(value: 0.0), NSNumber(value: 0.6), NSNumber(value: 1.0)]
        backgroundGradient.startPoint = CGPoint(x: 1.0, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.8, y: 1.0)
        
        return backgroundGradient
    }
}

enum Theme: String, CaseIterable {
    case pink
    case blue
    case purple
    case green
    
    var colorPrimaryLight: UIColor {
        switch self {
        case .pink: return UIColor.colorFromHexString("#ffbde4")
        case .blue: return UIColor.colorFromHexString("#a3d3ff")
        case .purple: return UIColor.colorFromHexString("#be9df5")
        case .green: return UIColor.colorFromHexString("#4ecc84")
        }
    }
    
    var colorPrimary: UIColor {
        switch self {
        case .pink: return UIColor.colorFromHexString("#E4A9CC")
        case .blue: return UIColor.colorFromHexString("#9ECCF6")
        case .purple: return UIColor.colorFromHexString("#977cc2")
        case .green: return UIColor.colorFromHexString("#3A9963")
        }
    }
    
    var colorPrimaryDark: UIColor {
        switch self {
        case .pink: return UIColor.colorFromHexString("#b0829e")
        case .blue: return UIColor.colorFromHexString("#7ca0c2")
        case .purple: return UIColor.colorFromHexString("#6f5b8f")
        case .green: return UIColor.colorFromHexString("#276642")
        }
    }
    
    var colorAccent: UIColor {
        switch self {
        case .pink: return UIColor.colorFromHexString("#9ECCF6")
        case .blue: return UIColor.colorFromHexString("#E4A9CC")
        case .purple: return UIColor.colorFromHexString("#9ECCF6")
        case .green: return UIColor.colorFromHexString("#57acd4")
        }
    }
    
    func getDisplayName() -> String {
        switch self {
        case .pink: return NSLocalizedString("pink", comment: "")
        case .blue: return NSLocalizedString("blue", comment: "")
        case .purple: return NSLocalizedString("purple", comment: "")
        case .green: return NSLocalizedString("green", comment: "")
        }
    }
    
    func getIndex() -> Int {
        return Theme.allCases.firstIndex(of: self)!
    }
    
    static func getDisplayNamesArray() -> [String] {
        return Theme.allCases.map{theme in theme.getDisplayName()}
    }
}
