//
//  Cedric.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public class Cedric: NSObject {
    
    internal var delegates: MulticastDelegate<CedricDelegate>
    
    private var items: ConcurrentArray<DownloadItem>
    private let group: LimitedOperationGroup
    private let configuration: CedricConfiguration
    private var lastError: Error?
    private let fileManager: FileManagerType
    private var session: URLSession!
    
    public convenience init(configuration: CedricConfiguration = CedricConfiguration.default, delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.init(configuration: configuration,
                  fileManager: DownloadsFileManager(withBaseDownloadsDirectoryName: configuration.baseDownloadsDirectoryName),
                  delegateQueue: delegateQueue)
    }
    
    internal init(configuration: CedricConfiguration = CedricConfiguration.default, fileManager: FileManagerType = DownloadsFileManager(withBaseDownloadsDirectoryName: "Downloads"), delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.items = ConcurrentArray<DownloadItem>()
        self.configuration = configuration
        self.group = configuration.limitedGroup()
        self.fileManager = fileManager
        delegates = MulticastDelegate<CedricDelegate>(delegateQueue: delegateQueue)
        
        let sessionConfiguration = URLSessionConfiguration.default
        if #available(iOS 11.0, *) {
            sessionConfiguration.waitsForConnectivity = true
        }
        
        super.init()
        self.session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: configuration.queue)
    }
    
    /// Schedule multiple downloads
    ///
    /// - Parameter resources: Resources to download
    public func enqueueMultipleDownloads(forResources resources: [DownloadResource]) throws {
        try resources.forEach { try enqueueDownload(forResource: $0) }
    }
    
    /// Add new download to Cedric's queue
    ///
    /// - Parameter resouce: resource to be downloaded
    public func enqueueDownload(forResource resource: DownloadResource) throws {
        cleanQueueStatisticsIfNeeded()
        let item = try DownloadItem(resource: resource, fileManager: fileManager, session: session)
        
        switch resource.mode {
        case .newFile:
            items.append(item)
        case .notDownloadIfExists:
            if let existing = existingFileIfAvailable(forExpectedFilename: resource.destinationName) {
                delegates.invoke { $0.cedric(self, didFinishDownloadingResource: resource, toFile: existing) }
                item.cancel()
                return
            } else {
                guard !items.contains(where: { $0.resource.destinationName == resource.destinationName }) else { return }
                items.append(item)
            }
        }

        createAndScheduleOperation(forItem: item)
    }
    
    /// Cancel downloading resources with id
    ///
    /// - Parameter id: identifier of resource to be cancel (please not that there might be multiple resources with the same identifier, all of them will be canceled)
    public func cancel(downloadingResourcesWithId id: String) {
        items.filter { $0.resource.id == id }
            .forEach {
                $0.cancel()
                remove(downloadItem: $0)
            }
    }
    
    /// Cancel all running downloads
    public func cancelAllDownloads() {
        items.forEach { $0.cancel() }
        items.removeAll()
    }
    
    /// Insert new delegate for multicast
    ///
    /// - Parameter object: Object
    public func addDelegate<T: CedricDelegate>(_ object: T) {
        delegates.addDelegate(object)
    }
    
    /// Remove particular delegate from multicast
    ///
    /// - Parameter object: Object
    public func removeDelegate<T: CedricDelegate>(_ object: T) {
        delegates.removeDelegate(object)
    }
    
    /// Returns download task for state observing
    ///
    /// - Parameter resource: Resource related with task (if using newFile mode first matching task is returned)
    /// - Returns: URLSessionDownloadTask for observing state / progress 
    public func downloadTask(forResource resource: DownloadResource) -> URLSessionDownloadTask? {
        return downloadTask(forResourceWithId: resource.id)
    }
    
    /// Returns download task for state observing
    ///
    /// - Parameter resourceId: Id of resource related with task (if using newFile mode first matching task is returned)
    /// - Returns: URLSessionDownloadTask for observing state / progress
    public func downloadTask(forResourceWithId resourceId: String) -> URLSessionDownloadTask? {
        return items.first(where: { $0.resource.id == resourceId })?.task
    }
    
    /// Check is cedric currently downloading resource with particular id
    ///
    /// - Parameter id: Unique id of resource
    public func isDownloading(resourceWithId id: String) -> Bool {
        return items.contains(where: { $0.resource.id == id })
    }

    /// Remove all files downloaded by Cedric
    ///
    /// - Throws: Exceptions occured while removing files
    public func cleanDownloadsDirectory() throws {
        try fileManager.cleanDownloadsDirectory()
    }
    
    /// Remove particular file
    ///
    /// - Parameter file: File to remove
    /// - Throws: Exceptions occured while removing file
    public func remove(downloadedFile file: DownloadedFile) throws {
        let url = try file.url()
        try fileManager.removeFile(atPath: url)
    }

    /// Get file for expected filename
    ///
    /// - Parameter filename: expected filename
    /// - Returns: DownloadedFile object if file exists at path
    public func existingFileIfAvailable(forExpectedFilename filename: String) -> DownloadedFile? {
        let url = try? fileManager.downloadsDirectory(create: false).appendingPathComponent(filename)
        guard let unwrappedUrl = url, FileManager.default.fileExists(atPath: unwrappedUrl.path) else { return nil }
        return try? DownloadedFile(absolutePath: unwrappedUrl)
    }
    
    /// Return active tasks
    ///
    /// - Returns: Currently under operation tasks
    public func getActiveTasks() -> [URLSessionDownloadTask] {
        return items.map{ $0.task }
            .compactMap { $0 }
    }
    
    private func cleanQueueStatisticsIfNeeded() {
        guard items.isEmpty else { return }
        lastError = nil
    }
    
    private func createAndScheduleOperation(forItem item: DownloadItem) {
        let operation = BlockOperation(block: { [weak item] in
            // prevent locking queue
            guard item != nil else { return }
            let semaphore = DispatchSemaphore(value: 0)
            
            item?.completionBlock = { [weak semaphore] in
                semaphore?.signal()
            }

            item?.resume()
            semaphore.wait()
        })
    
        group.addAsyncOperation(operation: operation)
        delegates.invoke { $0.cedric(self, didStartDownloadingResource: item.resource, withTask: item.task) }
    }
    
    fileprivate func remove(downloadItem item: DownloadItem) {
        items.remove(where: { $0 == item })
        
        if items.isEmpty {
            delegates.invoke({ $0.cedric(self, didFinishWithMostRecentError: self.lastError) })
        }
    }
}

extension Cedric: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let item = item(forDownloadTask: task) else { return }
        let downloadTask = task as! URLSessionDownloadTask
        delegates.invoke{ $0.cedric(self, didCompleteWithError: error, withTask: downloadTask, whenDownloadingResource: item.resource) }
        item.completionBlock?()
        remove(downloadItem: item)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let item = item(forDownloadTask: downloadTask) else { return }
        // single item progress report
        delegates.invoke { $0.cedric(self, didUpdateStatusOfTask: downloadTask, relatedToResource: item.resource) }

        // maybe should consider some groupped resources progress reporting ...
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let item = item(forDownloadTask: downloadTask) else { return }
        do {
            let newLocation = try item.moveToProperLocation(from: location)
            let file = try DownloadedFile(absolutePath: newLocation)
            delegates.invoke { $0.cedric(self, didFinishDownloadingResource: item.resource, toFile: file) }
        } catch let error {
            delegates.invoke { $0.cedric(self, didCompleteWithError: error, withTask: downloadTask, whenDownloadingResource: item.resource) }
        }
        item.completionBlock?()
        remove(downloadItem: item)
    }
    
    private func item(forDownloadTask task: URLSessionTask) -> DownloadItem? {
        return items.first(where: { $0.task.taskIdentifier == task.taskIdentifier && $0.task.taskDescription == task.taskDescription })
    }
}
