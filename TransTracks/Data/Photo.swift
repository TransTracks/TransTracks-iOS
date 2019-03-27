//
//  Photo.swift
//  TransTracks
//
//  Created by Cassie Wilson on 14/3/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData

extension Photo {
    static let FIELD_EPOCH_DAY = "epochDay"
    
    private static func count(_ predicate: NSPredicate, _ context: NSManagedObjectContext) -> Int{
        let request:NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = predicate
        return (try? context.count(for: request)) ?? 0
    }
    
    static func nextCount(_ currentEpochDay: Int,context: NSManagedObjectContext) -> Int {
        let predicate = NSPredicate(format: "\(Photo.FIELD_EPOCH_DAY) > %d", currentEpochDay)
        return count(predicate, context)
    }
    
    static func previousCount(_ currentEpochDay: Int,context: NSManagedObjectContext) -> Int {
        let predicate = NSPredicate(format: "\(Photo.FIELD_EPOCH_DAY) < %d", currentEpochDay)
        return count(predicate, context)
    }
}
