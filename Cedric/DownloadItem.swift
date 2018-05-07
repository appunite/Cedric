//
//  DownloadItem.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal protocol DownloadItemDelegate: class {
    func item(_ item: DownloadItem, didCompleteWithError error: Error?)
    func item(_ item: DownloadItem, didDownloadBytes bytes: Int64)
    func item(_ item: DownloadItem, didFinishDownloadingTo location: URL)
}

internal class DownloadItem: NSObject {
    
    internal let resource: DownloadResource
    internal weak var delegate: DownloadItemDelegate?
    
    internal var state: URLSessionTask.State {
        return task?.state ?? .suspended
    }
    
    private(set) var totalBytesExpected: Int64?
    private(set) var bytesDownloaded: Int64
    private(set) var session: URLSession?
    private(set) var task: URLSessionDownloadTask?
    private(set) var completed = false
    
    internal init(resource: DownloadResource, delegateQueue: OperationQueue?) {
        self.resource = resource
        self.bytesDownloaded = 0
        
        super.init()
        
        self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: delegateQueue)

        let task = session?.downloadTask(with: resource.source)
        task?.taskDescription = resource.id
        self.totalBytesExpected = task?.countOfBytesExpectedToReceive
        self.task = task
    }
    
    internal func cancel() {
        task?.cancel()
        session?.invalidateAndCancel()
    }
    
    internal func resume() {
        task?.resume()
    }
}

extension DownloadItem: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        delegate?.item(self, didCompleteWithError: error)
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        bytesDownloaded = totalBytesWritten
        totalBytesExpected = totalBytesExpectedToWrite
        delegate?.item(self, didDownloadBytes: bytesDownloaded)
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
            delegate?.item(self, didCompleteWithError: error)
        }
        
        session.finishTasksAndInvalidate()
    }
    
    private func path(forResource resource: DownloadResource) throws -> URL {
        
        let downloads = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads")
        
        var isDir: ObjCBool = true
        
        if !FileManager.default.fileExists(atPath: downloads.path, isDirectory: &isDir) {
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
