//
//  DownloadedFile.swift
//  Cedric
//
//  Created by Szymon Mrozek on 07.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public struct DownloadedFile {
    
    /// Relative path that should be stored
    public let relativePath: String
    
    /// Getter for url of file
    public func url() throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(relativePath)
    }
    
    internal init(absolutePath path: URL) throws {
        let documentsUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        relativePath = String(path.path.replacingOccurrences(of: documentsUrl.path, with: "").dropFirst())
    }
    
    public init(relativePath: String) {
        self.relativePath = relativePath
    }
    
    /// Get url of file with expected name
    ///
    /// - Parameter fileName: Preferred filename
    /// - Returns: URL if file with particular name exists in downloads directory
    public static func url(forPreferredFileName fileName: String) -> URL? {
        let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Downloads")
            .appendingPathComponent(fileName)
        
        guard let unwrappedUrl = url, FileManager.default.fileExists(atPath: unwrappedUrl.path) else { return nil }
        return unwrappedUrl
    }
}
