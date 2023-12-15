//
//  CedricConfiguration.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public struct CedricConfiguration {
    
    public enum Mode {
        case serial
        case parallel(max: Int)
    }
    
    /// Downloading mode serial / parallel
    public let mode: Mode
    
    /// Base queue of operations
    public let queue: OperationQueue
    
    /// Base downloads directory name, i.e. "this-property-value/your-file-name.png"
    public let baseDownloadsDirectoryName: String
    
    public init(mode: Mode, queue: OperationQueue = OperationQueue(), baseDownloadsDirectoryName: String = "Downloads") {
        self.mode = mode
        self.queue = queue
        self.baseDownloadsDirectoryName = baseDownloadsDirectoryName
    }
    
    /// Default configuration is parallel up to 25 tasks
    public static var `default`: CedricConfiguration {
        return CedricConfiguration(mode: .parallel(max: 25))
    }
    
    internal func limitedGroup() -> LimitedOperationGroup {
        switch mode {
        case .serial:
            return LimitedOperationGroup(limit: 1)
        case .parallel(let limit):
            return LimitedOperationGroup(limit: limit)
        }
    }
}
