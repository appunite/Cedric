//
//  ConcurrentArray.swift
//  Cedric
//
//  Created by Szymon Mrozek on 23.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal class ConcurrentArray<T> {
    fileprivate let queue = DispatchQueue(label: "com.cedric.management.queue",
                                          attributes: .concurrent)
    fileprivate var array = [T]()
}

extension ConcurrentArray {
    
    internal var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }
    
    internal var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }
}

// Immutable

extension ConcurrentArray {

    internal func first(where predicate: (T) -> Bool) -> T? {
        var result: T?
        queue.sync { result = self.array.first(where: predicate) }
        return result
    }

    internal func filter(_ isIncluded: (T) -> Bool) -> [T] {
        var result = [T]()
        queue.sync { result = self.array.filter(isIncluded) }
        return result
    }
    
    internal func index(where predicate: (T) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.array.firstIndex(where: predicate) }
        return result
    }
    
    internal func map<ElementOfResult>(_ transform: (T) -> ElementOfResult) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.array.map(transform) }
        return result
    }
    
    func forEach(_ body: (T) -> Void) {
        queue.sync { self.array.forEach(body) }
    }
    
    func contains(where predicate: (T) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(where: predicate) }
        return result
    }
}

// Mutable
extension ConcurrentArray {
    internal func append( _ element: T) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }

    internal func remove(where predicate: @escaping (T) -> Bool) {
        queue.async(flags: .barrier) {
            guard let index = self.array.firstIndex(where: predicate) else { return }
            self.array.remove(at: index)
        }
    }
    
    internal func removeAll() {
        queue.async(flags: .barrier) {
            self.array.removeAll()
        }
    }

    internal subscript(index: Int) -> T? {
        get {
            var result: T?
            
            queue.sync {
                guard self.array.startIndex..<self.array.endIndex ~= index else { return }
                result = self.array[index]
            }
            
            return result
        }
        set {
            guard let newValue = newValue else { return }
            
            queue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
    }
}

extension ConcurrentArray where T: Equatable {
    internal func contains(_ element: T) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(element) }
        return result
    }
}
