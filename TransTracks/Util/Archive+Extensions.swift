//
// Created by Cassie Wilson on 19/2/21.
// Copyright (c) 2021 TransTracks. All rights reserved.
//

import Foundation
import ZIPFoundation

extension Archive {
    func addDirectoryRecursively(_ directory: URL,
                                 compressionMethod: CompressionMethod = .none,
                                 bufferSize: Int = defaultWriteChunkSize,
                                 progress: Progress? = nil, currentDepth: Int = 0) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        
        for item in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try addDirectoryRecursively(
                            item, compressionMethod: compressionMethod,
                            bufferSize: bufferSize,
                            progress: progress,
                            currentDepth: currentDepth + 1
                    )
                } else {
                    let (filePath, fileRelativeTo) = Archive.getPathComponents(file: item, depth: currentDepth + 1)
                    try addEntry(
                            with: filePath,
                            relativeTo: fileRelativeTo,
                            compressionMethod: compressionMethod,
                            bufferSize: bufferSize,
                            progress: progress
                    )
                }
            }
        }
    }
    
    private static func getPathComponents(file: URL, depth: Int) -> (String, URL) {
        var path = file.lastPathComponent
        var relativeTo = file.deletingLastPathComponent()
        var count = 0
        
        while (count < depth) {
            path = URL(string: relativeTo.lastPathComponent)!.appendingPathComponent(path).path
            relativeTo = relativeTo.deletingLastPathComponent()
            count += 1
        }
        
        return (path, relativeTo)
    }
}
