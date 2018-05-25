//
//  DownloadItem.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal protocol DownloadItemDelegate: class {
    func item(_ item: DownloadItem, withTask task: URLSessionDownloadTask, didCompleteWithError error: Error?)
    func item(_ item: DownloadItem, didUpdateStatusOfTask task: URLSessionDownloadTask)
    func item(_ item: DownloadItem, didFinishDownloadingTo location: URL)
}

internal class DownloadItem: NSObject {
    
    internal let resource: DownloadResource
    internal weak var delegate: DownloadItemDelegate?
    internal weak var fileManager: FileManagerType!
    
    internal var completionBlock: (() -> Void)? // internal indicate that task is finished

    private var session: URLSession?
    private(set) var task: URLSessionDownloadTask?
    private(set) var completed = false
    
    internal init(resource: DownloadResource, delegateQueue: OperationQueue?, fileManager: FileManagerType) throws {
        self.resource = resource
        self.fileManager = fileManager
        
        super.init()

        let configuration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    
        guard let downloadUrl = resource.source else {
            throw DownloadError.missingURL
        }
        
        let task = session?.downloadTask(with: downloadUrl)
        task?.taskDescription = resource.id
        self.task = task
    }
    
    internal func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
        completionBlock?()
    }
    
    internal func resume() {
        task?.resume()
    }
    
    internal func releaseReferences() {
        task = nil
        session = nil
    }
}

extension DownloadItem: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        delegate?.item(self, withTask: task as! URLSessionDownloadTask, didCompleteWithError: error)
        session.finishTasksAndInvalidate()
        completionBlock?()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        delegate?.item(self, didUpdateStatusOfTask: downloadTask)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        do {
            let destination = try path(forResource: resource)
            try fileManager.move(fromPath: location, toPath: destination, resource: resource)
            completed = true
            delegate?.item(self, didFinishDownloadingTo: destination)
        } catch let error {
            delegate?.item(self, withTask: downloadTask, didCompleteWithError: error)
        }
        
        session.finishTasksAndInvalidate()
        completionBlock?()
    }
    
    private func path(forResource resource: DownloadResource) throws -> URL {
        switch resource.mode {
        case .newFile:
            return try fileManager.createUrl(forName: resource.destinationName, unique: true)
        case .notDownloadIfExists:
            return try fileManager.createUrl(forName: resource.destinationName, unique: false)
        }
    }
}
