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
        case paralell(max: Int)
    }
    
    public let queue: OperationQueue
    public let mode: Mode
    
    public init(mode: Mode, queue: OperationQueue = OperationQueue()) {
        self.queue = queue
        self.mode = mode
    }
    
    public static var `default`: CedricConfiguration {
        return CedricConfiguration(mode: .paralell(max: 25))
    }
    
    internal func limitedGroup() -> LimitedOperationGroup {
        switch mode {
        case .serial:
            return LimitedOperationGroup(limit: 1)
        case .paralell(let limit):
            return LimitedOperationGroup(limit: limit)
        }
    }
}
