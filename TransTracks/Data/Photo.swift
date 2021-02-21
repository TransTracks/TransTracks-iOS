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
    static let FIELD_ID = "id"
    static let FIELD_TIMESTAMP = "timestamp"
    static let FIELD_TYPE = "type"
    
    private static func count(_ predicate: NSPredicate, _ context: NSManagedObjectContext) -> Int{
        let request:NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = predicate
        return (try? context.count(for: request)) ?? 0
    }
    
    static func next(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Photo? {
        let request:NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = nextPredicate(currentEpochDay)
        request.sortDescriptors = [NSSortDescriptor(key: Photo.FIELD_EPOCH_DAY, ascending: true)]
        request.fetchLimit = 1
        
        return (try? context.fetch(request))?.first
    }
    
    static func nextCount(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Int {
        return count(nextPredicate(currentEpochDay), context)
    }
    
    private static func nextPredicate(_ currentEpochDay: Int) -> NSPredicate {
        return NSPredicate(format: "\(Photo.FIELD_EPOCH_DAY) > %d", currentEpochDay)
    }
    
    static func previous(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Photo? {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = previousPredicate(currentEpochDay)
        request.sortDescriptors = [NSSortDescriptor(key: Photo.FIELD_EPOCH_DAY, ascending: false)]
        request.fetchLimit = 1
        
        return (try? context.fetch(request))?.first
    }
    
    static func previousCount(_ currentEpochDay: Int, context: NSManagedObjectContext) -> Int {
        return count(previousPredicate(currentEpochDay), context)
    }
    
    private static func previousPredicate(_ currentEpochDay: Int) -> NSPredicate {
        return NSPredicate(format: "\(Photo.FIELD_EPOCH_DAY) < %d", currentEpochDay)
    }
    
    static func fromJson(json: [String: Any], context: NSManagedObjectContext) throws -> Photo {
        let photo = Photo(context: context)
        
        if let id = json[CodingKeys.id.rawValue] as? String {
            photo.id = UUID(uuidString: id)
        }
        
        if let epochDay = json[CodingKeys.epochDay.rawValue] as? Int {
            photo.epochDay = Int64(epochDay)
        }
        
        if let timestamp = json[CodingKeys.timestamp.rawValue] as? Double {
            photo.timestamp = Date(timeIntervalSince1970: timestamp / 1000)
        }
        
        if let filePath = json[CodingKeys.fileName.rawValue] as? String {
            photo.filePath = filePath
        }
        
        if let type = json[CodingKeys.type.rawValue] as? Int {
            photo.type = Int16(type)
        }
        
        return photo
    }
}

extension Photo: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(epochDay, forKey: .epochDay)
        
        if let timestamp = timestamp {
            try container.encode(Int(timestamp.timeIntervalSince1970 * 1000), forKey: .timestamp)
        }
        
        try container.encode(filePath, forKey: .fileName)
        try container.encode(type, forKey: .type)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case epochDay
        case timestamp
        case fileName
        case type
    }
}

enum PhotoType: Int, CaseIterable {
    //These integers are IDs and shouldn't be reused or changed
    
    case face = 0
    case body = 1
    
    func getDisplayName() -> String {
        switch self {
        case .face: return NSLocalizedString("face", comment: "")
        case .body:return NSLocalizedString("body", comment: "")
        }
    }
    
    static func getDisplayNamesArray() -> [String] {
        return PhotoType.allCases.map{type in type.getDisplayName()}
    }
    
    func getIndex() -> Int {
        return PhotoType.allCases.firstIndex(of: self)!
    }
}
