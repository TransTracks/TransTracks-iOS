//
//  FileUtil.swift
//  TransTracks
//
//  Created by Cassie Wilson on 1/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

class FileUtil {
    
    //MARK: Constants
    
    private static let PHOTOS = "photos"
    
    //MARK: Photos
    
    static func getNewImageFileURL(photoDate: Date) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        let photoDateString = formatter.string(from: photoDate)
        let timeStamp = formatter.string(from: Date())
        
        let filename = "photo_\(photoDateString)_imported_\(timeStamp).jpg"
        
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
            
            let photosDirectory = documentDirectory.appendingPathComponent(PHOTOS, isDirectory: true)
            if !fileManager.fileExists(atPath: photosDirectory.path){
                try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
           return photosDirectory.appendingPathComponent(filename)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func getFullImagePath(filename: String) -> URL? {
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            
            let photoFile = documentDirectory.appendingPathComponent(PHOTOS, isDirectory: true).appendingPathComponent(filename)
            if fileManager.fileExists(atPath: photoFile.path){
                return photoFile
            } else {
                return nil
            }
        } catch {
            print(error)
            return nil
        }
    }
}
