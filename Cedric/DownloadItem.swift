//
//  DownloadItem.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal class DownloadItem: Equatable {
    internal let resource: DownloadResource
    internal weak var fileManager: FileManagerType!
    internal var completionBlock: (() -> Void)? // internal indicate that task is finished
    internal let task: URLSessionDownloadTask
    
    private(set) var completed = false
    
    internal init(resource: DownloadResource, fileManager: FileManagerType, session: URLSession) throws {
        self.resource = resource
        self.fileManager = fileManager
    
        guard let downloadUrl = resource.source else {
            throw DownloadError.missingURL
        }
        
        let task = session.downloadTask(with: downloadUrl)
        task.taskDescription = resource.id
        self.task = task
    }
    
    internal func cancel() {
        task.cancel()
        completionBlock?()
    }
    
    internal func resume() {
        task.resume()
    }
    
    internal func moveToProperLocation(from location: URL) throws -> URL {
        let destination = try path(forResource: resource)
        try fileManager.move(fromPath: location, toPath: destination, resource: resource)
        completed = true
        return destination
    }
    
    fileprivate func path(forResource resource: DownloadResource) throws -> URL {
        switch resource.mode {
        case .newFile:
            return try fileManager.createUrl(forName: resource.destinationName, unique: true)
        case .notDownloadIfExists:
            return try fileManager.createUrl(forName: resource.destinationName, unique: false)
        }
    }
    
    static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        return lhs.resource == rhs.resource
            && lhs.task == rhs.task
    }
}
