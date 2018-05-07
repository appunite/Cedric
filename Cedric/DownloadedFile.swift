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
}
