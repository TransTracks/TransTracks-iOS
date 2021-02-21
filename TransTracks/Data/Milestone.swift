//
//  Milestone.swift
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

extension Milestone {
    static let FIELD_EPOCH_DAY = "epochDay"
    static let FIELD_TIMESTAMP = "timestamp"
    
    private static func count(_ predicate: NSPredicate, _ context: NSManagedObjectContext) -> Int {
        let request:NSFetchRequest<Milestone> = Milestone.fetchRequest()
        request.predicate = predicate
        return (try? context.count(for: request)) ?? 0
    }
    
    static func hasMilestones(_ currentEpochDay: Int,context: NSManagedObjectContext) -> Bool{
        let predicate = NSPredicate(format: "\(Milestone.FIELD_EPOCH_DAY) = %d", currentEpochDay)
        return count(predicate, context) > 0
    }
    
    static func next(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Milestone? {
        let request:NSFetchRequest<Milestone> = Milestone.fetchRequest()
        request.predicate = nextPredicate(currentEpochDay)
        request.sortDescriptors = [NSSortDescriptor(key: Milestone.FIELD_EPOCH_DAY, ascending: true)]
        request.fetchLimit = 1
        
        return (try? context.fetch(request))?.first
    }
    
    static func nextCount(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Int {
        return count(nextPredicate(currentEpochDay), context)
    }
    
    static func nextPredicate(_ currentEpochDay: Int) -> NSPredicate {
        return NSPredicate(format: "\(Milestone.FIELD_EPOCH_DAY) > %d", currentEpochDay)
    }
    
    static func previous(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Milestone? {
        let request: NSFetchRequest<Milestone> = Milestone.fetchRequest()
        request.predicate = previousPredicate(currentEpochDay)
        request.sortDescriptors = [NSSortDescriptor(key: Milestone.FIELD_EPOCH_DAY, ascending: false)]
        request.fetchLimit = 1
        
        return (try? context.fetch(request))?.first
    }
    
    static func previousCount(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Int {
        return count(previousPredicate(currentEpochDay), context)
    }
    
    static func previousPredicate(_ currentEpochDay: Int) -> NSPredicate {
        return NSPredicate(format: "\(Milestone.FIELD_EPOCH_DAY) < %d", currentEpochDay)
    }
    
    static func fromJson(json: [String: Any], context: NSManagedObjectContext) throws -> Milestone {
        let milestone = Milestone(context: context)
        
        if let id = json[CodingKeys.id.rawValue] as? String {
            milestone.id = UUID(uuidString: id)
        }
        
        if let epochDay = json[CodingKeys.epochDay.rawValue] as? Int {
            milestone.epochDay = Int64(epochDay)
        }
        
        if let timestamp = json[CodingKeys.timestamp.rawValue] as? Double {
            milestone.timestamp = Date(timeIntervalSince1970: timestamp / 1000)
        }
        
        if let title = json[CodingKeys.title.rawValue] as? String {
            milestone.title = title
        }
        
        if let userDescription = json[CodingKeys.userDescription.rawValue] as? String {
            milestone.userDescription = userDescription
        }
        
        return milestone
    }
}

extension Milestone: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(epochDay, forKey: .epochDay)
        
        if let timestamp = timestamp {
            try container.encode(Int(timestamp.timeIntervalSince1970 * 1000), forKey: .timestamp)
        }
        
        try container.encode(title, forKey: .title)
        try container.encode(userDescription, forKey: .userDescription)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case epochDay
        case timestamp
        case title
        case userDescription = "description"
    }
}
