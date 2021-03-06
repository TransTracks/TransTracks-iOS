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
    
    //MARK: General
    
    static func deleteFile(file: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: file)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    static func timestampFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }
    
    //MARK: Photos
    
    static func getPhotoDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documentDirectory = try fileManager.url(
                for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let photosDirectory = documentDirectory.appendingPathComponent("photos", isDirectory: true)
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
        return photosDirectory
    }
    
    static func getNewImageFileURL(photoDate: Date) -> URL? {
        let formatter = timestampFormatter()
        
        let photoDateString = formatter.string(from: photoDate)
        let timeStamp = formatter.string(from: Date())
        
        let filename = "photo_\(photoDateString)_imported_\(timeStamp).jpg"
        do {
            return try getPhotoDirectory().appendingPathComponent(filename)
        } catch {
            print(error)
            return nil
        }
    }
    
    static func getFullImagePath(filename: String) -> URL? {
        let fileManager = FileManager.default
        do {
            let photoFile = try getPhotoDirectory().appendingPathComponent(filename)
            if fileManager.fileExists(atPath: photoFile.path) {
                return photoFile
            } else {
                return nil
            }
        } catch {
            print(error)
            return nil
        }
    }
    
    //MARK: Temp
    
    static func getNewTempFileURL(fileName: String) throws -> URL {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.temporaryDirectory.appendingPathComponent("temp", isDirectory: true)
        if !fileManager.fileExists(atPath: documentDirectory.path) {
            try fileManager.createDirectory(at: documentDirectory, withIntermediateDirectories: true)
        }
        return documentDirectory.appendingPathComponent(fileName)
    }
}
