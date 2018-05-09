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
    internal var completionBlock: (() -> Void)? // indicate that task is finished

    private var session: URLSession?
    private(set) var task: URLSessionDownloadTask!
    private(set) var completed = false
    
    internal init(resource: DownloadResource, delegateQueue: OperationQueue?) {
        self.resource = resource
        
        super.init()

        let configuration = URLSessionConfiguration.default
        
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    
        let task = session?.downloadTask(with: resource.source)
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
        delegate?.item(self, withTask: self.task, didCompleteWithError: error)
        session.finishTasksAndInvalidate()
        completionBlock?()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        delegate?.item(self, didUpdateStatusOfTask: self.task)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        do {
            let destination = try path(forResource: resource)
            try FileManager.default.moveItem(at: location, to: destination)
            if let attributes = resource.attributes {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: destination.path)
            }
            completed = true
            delegate?.item(self, didFinishDownloadingTo: destination)
        } catch let error {
            delegate?.item(self, withTask: self.task, didCompleteWithError: error)
        }
        
        session.finishTasksAndInvalidate()
        completionBlock?()
    }
    
    private func path(forResource resource: DownloadResource) throws -> URL {
        
        let downloads = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads")
        
        var isDir: ObjCBool = true
        
        if FileManager.default.fileExists(atPath: downloads.path, isDirectory: &isDir) == false {
            try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true, attributes: nil)
        }

        switch resource.mode {
        case .newFile:
            return uniquePath(forFilename: resource.destinationName, inDownloadDirectory: downloads)
        case .notDownloadIfExists:
            return downloads.appendingPathComponent(resource.destinationName)
        }
    }
    
    private func uniquePath(forFilename filename: String, inDownloadDirectory downloads: URL) -> URL {
        let basePath = downloads.appendingPathComponent(resource.destinationName)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension: String
        if fileExtension.count > 0 {
            filenameWithoutExtension = String(filename.dropLast(fileExtension.count + 1))
        } else {
            filenameWithoutExtension = filename
        }
        
        var destinationPath = basePath
        var existing = 0
        
        while FileManager.default.fileExists(atPath: destinationPath.path) {
            existing += 1
            
            let newFilenameWithoutExtension = "\(filenameWithoutExtension)(\(existing))"
            destinationPath = downloads.appendingPathComponent(newFilenameWithoutExtension).appendingPathExtension(fileExtension)
        }
        
        return destinationPath
    }
}

// Debugging helper

internal extension URLSessionDownloadTask.State {
    var description: String {
        switch self {
        case .canceling: return "Canceling"
        case .completed: return "Completed"
        case .running: return "Running"
        case .suspended: return "Suspended"
        }
    }
}
