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
        let asGMT = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: self)
        
        let y: Int = asGMT.year!
        let m: Int = asGMT.month!
        
        var total = 0
        
        total += 365 * y
        
        if(y >= 0){
            total += (y + 3) / 4 - (y + 99) / 100 + (y + 399) / 400
        } else{
            total -= y / -4 - y / -100 + y / -400
        }
        
        total += (367 * m - 362) / 12
        
        total += asGMT.day! - 1
        if (m > 2) {
            total -= 1
            if (!asGMT.isLeapYear()!) {
                total -= 1
            }
        }
        
        return total - Date.DAYS_0000_TO_1970
    }
    
    func toFullDateString() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd/MM/yyyy")
        
        return formatter.string(from: self)
    }
    
    //MARK: Constants
    
    /**
     * The number of days in a 400 year cycle.
     */
    private static let DAYS_PER_CYCLE = 146097
    
    /**
     * The number of days from year zero to year 1970.
     * There are five 400 year cycles from year zero to 2000.
     * There are 7 leap years from 1970 to 2000.
     */
    private static let DAYS_0000_TO_1970 = (DAYS_PER_CYCLE * 5) - (30 * 365 + 7)
    
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
        var zeroDay:Int = epochDay + Date.DAYS_0000_TO_1970
        // find the march-based year
        zeroDay -= 60  // adjust to 0000-03-01 so leap day is at end of four year cycle
        var adjust = 0
        if (zeroDay < 0) {
            // adjust negative years to positive for calculation
            let adjustCycles = (zeroDay + 1) / Date.DAYS_PER_CYCLE - 1
            adjust = adjustCycles * 400;
            zeroDay += -adjustCycles * Date.DAYS_PER_CYCLE
        }
        var yearEst = (400 * zeroDay + 591) / Date.DAYS_PER_CYCLE
        var doyEst = zeroDay - (365 * yearEst + yearEst / 4 - yearEst / 100 + yearEst / 400)
        if (doyEst < 0) {
            // fix estimate
            yearEst -= 1
            doyEst = zeroDay - (365 * yearEst + yearEst / 4 - yearEst / 100 + yearEst / 400)
        }
        yearEst += adjust;  // reset any negative year
        let marchDoy0 = doyEst;
        
        // convert march-based values back to january-based
        let marchMonth0 = (marchDoy0 * 5 + 2) / 153;
        let month = (marchMonth0 + 2) % 12 + 1;
        let dom = marchDoy0 - (marchMonth0 * 306 + 5) / 10 + 1;
        yearEst += marchMonth0 / 10;
        
        // Specify date components
        var dateComponents = DateComponents()
        dateComponents.year = yearEst
        dateComponents.month = month
        dateComponents.day = dom
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let userCalendar = Calendar.current // user calendar
        return userCalendar.date(from: dateComponents)!
    }
    
    static func ofEpochDay(_ epochDay: Int64) -> Date {
        return ofEpochDay(Int(epochDay))
    }
}
