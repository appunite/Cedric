//
//  Cedric.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public class Cedric {
    
    internal var delegates = MulticastDelegate<CedricDelegate>()
    
    private var items: [DownloadItem]
    private let group: LimitedOperationGroup
    private let configuration: CedricConfiguration
    private var lastError: Error?
    
    public init(configuration: CedricConfiguration = CedricConfiguration.default) {
        self.items = []
        self.configuration = configuration
        self.group = configuration.limitedGroup()
    }
    
    /// Schedule multiple downloads
    ///
    /// - Parameter resources: Resources to download
    public func enqueueMultipleDownloads(forResources resources: [DownloadResource]) {
        resources.forEach { enqueueDownload(forResource: $0) }
    }
    
    /// Add new download to Cedric's queue
    ///
    /// - Parameter resouce: resource to be downloaded
    public func enqueueDownload(forResource resource: DownloadResource) {
        cleanQueueStatisticsIfNeeded()
        let item = DownloadItem(resource: resource, delegateQueue: configuration.queue)
        
        switch resource.mode {
        case .newFile:
            items.append(item)
        case .notDownloadIfExists:
            if let existing = existingFileIfAvailable(forResource: resource) {
                DispatchQueue.main.async {
                    self.delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: resource, toFile: existing) })
                }
                return
            } else {
                guard items.contains(where: { $0.resource.id == resource.id }) == false else { return } 
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
            .filter { $0.completed == false }
            .forEach { $0.cancel() }
    }
    
    /// Cancel all running downloads
    public func cancelAllDownloads() {
        items.filter { $0.completed == false }
            .forEach { $0.cancel() }
    }
    
    /// Insert new delegate for multicast
    ///
    /// - Parameter object: Object
    public func addDelegate<T: CedricDelegate>(_ object: T) {
        DispatchQueue.main.async {
            self.delegates.addDelegate(object)
        }
    }
    
    /// Remove particular delegate from multicast
    ///
    /// - Parameter object: Object
    public func removeDelegate<T: CedricDelegate>(_ object: T) {
        DispatchQueue.main.async {
            self.delegates.removeDelegate(object)
        }
    }
    
    /// Returns download task for state observing
    ///
    /// - Parameter resource: Resource related with task (if using newFile mode first matching task is returned)
    /// - Returns: URLSessionDownloadTask for observing state / progress 
    public func downloadTask(forResource resource: DownloadResource) -> URLSessionDownloadTask? {
        return items.first(where: { $0.resource.id == resource.id })?.task
    }

    /// Remove all files downloaded by Cedric
    ///
    /// - Throws: Exception occured while removing files
    public func cleanDownloadsDirectory() throws {
        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads")
        let content = try FileManager.default.contentsOfDirectory(atPath: documents.path)
        try content.forEach({ try FileManager.default.removeItem(atPath: "\(documents.path)/\($0)")})
    }
    
    public func remove(downloadedFile file: DownloadedFile) throws {
        let url = try file.url()
        try FileManager.default.removeItem(at: url)
    }
    
    private func existingFileIfAvailable(forResource resource: DownloadResource) -> DownloadedFile? {
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("Downloads").appendingPathComponent(resource.destinationName) else { return nil }
        
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? DownloadedFile(absolutePath: url)
    }
    
    private func cleanQueueStatisticsIfNeeded() {
        guard items.isEmpty else { return }
        lastError = nil
    }
    
    private func createAndScheduleOperation(forItem item: DownloadItem) {
        item.delegate = self
        
        let operation = BlockOperation(block: { [weak self] in
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.delegates.invoke({ $0.cedric(self, didStartDownloadingResource: item.resource, withTask: item.task) })
            }
            
            item.completionBlock = {
                semaphore.signal()
            }
            item.resume()
            semaphore.wait()
        })
        
        group.addAsyncOperation(operation: operation)
    }
}

// MARK: - DownloadItemDelegate

extension Cedric: DownloadItemDelegate {
    
    func item(_ item: DownloadItem, withTask task: URLSessionDownloadTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.delegates.invoke({ $0.cedric(self, didCompleteWithError: error, withTask: task, whenDownloadingResource: item.resource) })
            self.remove(downloadItem: item)
        }
    }
    
    func item(_ item: DownloadItem, didUpdateStatusOfTask task: URLSessionDownloadTask) {
        // single item progress report
        
        DispatchQueue.main.async {
            self.delegates.invoke({ $0.cedric(self, didUpdateStatusOfTask: task, relatedToResource: item.resource) })
        }
    }
    
    internal func item(_ item: DownloadItem, didFinishDownloadingTo location: URL) {
        do {
            let file = try DownloadedFile(absolutePath: location)
            DispatchQueue.main.async {
                self.delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: item.resource, toFile: file) })
            }
            remove(downloadItem: item)
        } catch let error {
            DispatchQueue.main.async {
                self.delegates.invoke({ $0.cedric(self, didCompleteWithError: error, withTask: item.task, whenDownloadingResource: item.resource) })
            }
            remove(downloadItem: item)
        }
    }
    
    fileprivate func remove(downloadItem item: DownloadItem) {
        guard let index = items.index(of: item) else { return }
        let item = items[index]
        item.delegate = nil
        items.remove(at: index)
        
        guard items.isEmpty else { return }
        DispatchQueue.main.async {
            self.delegates.invoke({ $0.cedric(self, didFinishWithMostRecentError: self.lastError)})
        }
    }
}
