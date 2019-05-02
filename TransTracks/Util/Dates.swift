//
//  Dates.swift
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

import Foundation

extension Date {
    
    //MARK: Instance helpers
    
    func isBefore(_ other: Date) -> Bool {
        return self < other
    }
    
    func isAfter(_ other: Date) -> Bool {
        return self > other
    }
    
    func isLeapYear() -> Bool {
        return (( year % 100 != 0) && (year % 4 == 0)) || year % 400 == 0
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func toEpochDay() -> Int {
        let y = year
        let m = month
        
        var total = 0
        
        total += 365 * y
        
        if(y >= 0){
            total += (y + 3) / 4 - (y + 99) / 100 + (y + 399) / 400
        } else{
            total -= y / -4 - y / -100 + y / -400
        }
        
        total += (367 * m - 362) / 12
    
        total += day - 1
        if (m > 2) {
            total -= 1
            if (!isLeapYear()) {
                total -= 1
            }
        }
        
        return total - 719528;
    }
    
    func toFullDateString() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/yyyy")
        
        return formatter.string(from: self)
    }
    
    func toISODateString() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    //MARK: Static helpers
    
    static func stringForPeriodBetween(start: Date, end: Date) -> String {
        var returnString = ""
        
        let calendar = Calendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        
        let components = calendar.dateComponents([.year,.month,.day], from: date1, to: date2)
        
        if components.year != 0 {
            let format = NSLocalizedString("years", comment: "")
            returnString += String.localizedStringWithFormat(format, components.year!)
        }
        if components.month != 0 {
            if returnString.isNotEmpty {
                returnString += ", "
            }
            
            let format = NSLocalizedString("months", comment: "")
            returnString += String.localizedStringWithFormat(format, components.month!)
        }
        if components.day != 0 {
            if returnString.isNotEmpty {
                returnString += ", "
            }
            
            let format = NSLocalizedString("days", comment: "")
            returnString += String.localizedStringWithFormat(format, components.day!)
        }
        
        if returnString.isNotEmpty {
            return returnString
        } else {
            return NSLocalizedString("startDay", comment: "")
        }
    }
    
    static func today() -> Date {
        return Date().startOfDay()
    }
    
    static func getCurrentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    static func ofEpochDay(_ epochDay: Int) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(epochDay * 24 * 60 * 60))
    }
}
