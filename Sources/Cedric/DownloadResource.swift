//
//  DownloadResource.swift
//  Cedric
//
//  Created by Szymon Mrozek on 07.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public enum DownloadMode {
    case newFile
    case notDownloadIfExists
}

public struct DownloadResource: Equatable {
    /// Identifier of downloaded resource
    public let id: String
    
    /// Source from which file will be downloaded
    public let source: URL?
    
    /// Preferred destination name (might be different if using `newFile` mode)
    public let destinationName: String
    
    /// Downloading mode: newFile - always create new file even if exist for particular filename, notDownloadIfExist - reuse downloaded files
    public let mode: DownloadMode
    
    /// Attributes applied to downloaded file
    public let attributes: [FileAttributeKey: Any]?
    
    public init(id: String, source: URL?, destinationName: String, mode: DownloadMode = .notDownloadIfExists, attributes: [FileAttributeKey: Any]? = nil) {
        self.id = id
        self.source = source
        self.destinationName = destinationName
        self.mode = mode
        self.attributes = attributes
    }
    
    public static func == (lhs: DownloadResource, rhs: DownloadResource) -> Bool {
        return lhs.id == rhs.id && lhs.mode == rhs.mode && lhs.source == rhs.source && lhs.destinationName == rhs.destinationName
    }
}
