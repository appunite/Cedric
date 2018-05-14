//
//  Cedric.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public class Cedric {
    
    internal var delegates: MulticastDelegate<CedricDelegate>
    
    private var items: [DownloadItem]
    private let group: LimitedOperationGroup
    private let configuration: CedricConfiguration
    private var lastError: Error?
    private let fileManager: FileManagerType
    
    public init(configuration: CedricConfiguration = CedricConfiguration.default, delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.items = []
        self.configuration = configuration
        self.group = configuration.limitedGroup()
        self.fileManager = DownloadsFileManager()
        delegates = MulticastDelegate<CedricDelegate>(delegateQueue: delegateQueue)

    }
    
    internal init(configuration: CedricConfiguration = CedricConfiguration.default, fileManager: FileManagerType = DownloadsFileManager(), delegateQueue: DispatchQueue = DispatchQueue.main) {
        self.items = []
        self.configuration = configuration
        self.group = configuration.limitedGroup()
        self.fileManager = fileManager
        delegates = MulticastDelegate<CedricDelegate>(delegateQueue: delegateQueue)
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
        let item = try DownloadItem(resource: resource, delegateQueue: configuration.queue, fileManager: fileManager)
        
        switch resource.mode {
        case .newFile:
            items.append(item)
        case .notDownloadIfExists:
            if let existing = existingFileIfAvailable(forExpectedFilename: resource.destinationName) {
                delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: resource, toFile: existing) })
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
                $0.delegate = nil
                $0.cancel()
                remove(downloadItem: $0)
            }
    }
    
    /// Cancel all running downloads
    public func cancelAllDownloads() {
        items.forEach {
            $0.delegate = nil
            $0.cancel()
            remove(downloadItem: $0)
        }
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
        let url = try? DownloadsFileManager().downloadsDirectory().appendingPathComponent(filename)
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
        item.delegate = self
        
        let operation = BlockOperation(block: { [weak item] in
            guard let strongItem = item else { return }
            
            let semaphore = DispatchSemaphore(value: 0)
            
            strongItem.completionBlock = { [weak semaphore] in
                semaphore?.signal()
            }

            strongItem.resume()
            semaphore.wait()
        })
    
        group.addAsyncOperation(operation: operation)
        
        delegates.invoke({ [task = item.task!] in
            $0.cedric(self, didStartDownloadingResource: item.resource, withTask: task)
        })
    }
}

// MARK: - DownloadItemDelegate

extension Cedric: DownloadItemDelegate {
    internal func item(_ item: DownloadItem, withTask task: URLSessionDownloadTask, didCompleteWithError error: Error?) {
        delegates.invoke({ $0.cedric(self, didCompleteWithError: error, withTask: task, whenDownloadingResource: item.resource) })
        item.delegate = nil
        remove(downloadItem: item)
    }
    
    internal func item(_ item: DownloadItem, didUpdateStatusOfTask task: URLSessionDownloadTask) {
        // single item progress report
        delegates.invoke({ $0.cedric(self, didUpdateStatusOfTask: task, relatedToResource: item.resource) })
        
        // maybe should consider some groupped resources progress reporting ...
    }
    
    internal func item(_ item: DownloadItem, didFinishDownloadingTo location: URL) {
        do {
            let file = try DownloadedFile(absolutePath: location)
            delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: item.resource, toFile: file) })
        } catch let error {
            delegates.invoke({ [task = item.task!] in
                $0.cedric(self, didCompleteWithError: error, withTask: task, whenDownloadingResource: item.resource)
            })
        }
        
        item.delegate = nil
        remove(downloadItem: item)
    }
    
    fileprivate func remove(downloadItem item: DownloadItem) {
        guard let index = items.index(of: item) else { return }
        let item = items[index]

        items.remove(at: index)
        item.releaseReferences()
        
        guard items.isEmpty else { return }
        delegates.invoke({ $0.cedric(self, didFinishWithMostRecentError: self.lastError) })
    }
}
