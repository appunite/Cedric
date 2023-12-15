//
//  LimitedOperationGroup.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

/// It's just a simple wrapper around OperationQueue for making extensions later and prevent
/// containing two operation queues in one class
internal class LimitedOperationGroup {
    
    let queue: OperationQueue // queue used only for scheduling tasks
    let limit: Int
    
    internal init(limit: Int = 1) {
        self.queue = OperationQueue()
        queue.maxConcurrentOperationCount = limit
        self.limit = limit
    }
    
    internal func addAsyncOperation(operation: Operation) {
        queue.addOperation(operation)
    }
}
