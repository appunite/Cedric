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

    internal var isEmpty: Bool {
        return delegates.count == 0
    }
    
    internal init() {
        delegates = NSHashTable<AnyObject>.weakObjects()
    }
    
    internal func addDelegate(_ delegate: T) {
        delegates.add(delegate as AnyObject)
    }
    
    internal func removeDelegate(_ delegate: T) {
        delegates.remove(delegate as AnyObject)
    }
    
    internal func invoke(_ invocation: @escaping (T) -> ()) {
        DispatchQueue.main.async {
            for delegate in self.delegates.allObjects {
                invocation(delegate as! T)
            }
        }
    }
}
