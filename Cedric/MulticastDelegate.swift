//
//  MulticastDelegate.swift
//  Cedric
//
//  Created by Szymon Mrozek on 07.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal class MulticastDelegate<T> {
    
    private let delegates: NSHashTable<AnyObject>
    private let queue: DispatchQueue

    internal var isEmpty: Bool {
        return delegates.count == 0
    }
    
    internal init(delegateQueue queue: DispatchQueue) {
        delegates = NSHashTable<AnyObject>.weakObjects()
        self.queue = queue
    }
    
    internal func addDelegate(_ delegate: T) {
        queue.async { [weak self] in 
            self?.delegates.add(delegate as AnyObject)
        }
    }
    
    internal func removeDelegate(_ delegate: T) {
        queue.async { [weak self] in
            self?.delegates.remove(delegate as AnyObject)
        }
    }
    
    internal func invoke(_ invocation: @escaping (T) -> ()) {
        queue.async {
            for delegate in self.delegates.allObjects {
                invocation(delegate as! T)
            }
        }
    }
}
