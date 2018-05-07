//
//  Cedric.swift
//  Cedric
//
//  Created by Szymon Mrozek on 06.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public protocol CedricDelegate: class {
    /// Invoked when download did start for paricular resource
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - resource: Resource which download did start
    func cedric(_ cedric: Cedric, didStartDownloadingResource resource: DownloadResource)
    
    /// Invoked when next chunk of data is downloaded of particular item
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - bytesDownloaded: Total bytes downloaded
    ///   - totalBytesExpected: Total bytes expected to download
    ///   - resource: Resource related with download
    func cedric(_ cedric: Cedric, didDownloadBytes bytesDownloaded: Int64, fromTotalBytesExpected totalBytesExpected: Int64?, ofResource resource: DownloadResource)
    
    /// Invoked when particular resource downloading is finished
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - resource: Resource related with download
    ///   - location: Location where downloaded file is stored
    func cedric(_ cedric: Cedric, didFinishDownloadingResource resource: DownloadResource, toLocation location: URL)
    
    /// Invoked when error occured during downloading particular resource
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - error: Error that occured during downloading
    ///   - resource: Downloaded resource
    func cedric(_ cedric: Cedric, didCompleteWithError error: Error?, whenDownloadingResource resource: DownloadResource)
}

public class Cedric {
    
    fileprivate var delegates = MulticastDelegate<CedricDelegate>()
    private var items: [DownloadItem]
    private var operationQueue: OperationQueue
    
    public init(operationQueue: OperationQueue = OperationQueue()) {
        self.operationQueue = operationQueue
        self.items = []
    }
    
    /// Add new download to Cedric's queue
    ///
    /// - Parameter resouce: resource to be downloaded
    public func enqueueDownload(forResource resource: DownloadResource) {
        let item = DownloadItem(resource: resource, delegateQueue: operationQueue)
        
        switch resource.mode {
        case .newFile:
            items.append(item)
        case .notDownloadIfExists:
            if let existing = existingFileIfAvailable(forResource: resource) {
                delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: resource, toLocation: existing) })
                return
            } else {
                items.append(item)
            }
        }
        
        item.delegate = self
        item.resume()
        delegates.invoke({ $0.cedric(self, didStartDownloadingResource: resource) })
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
        delegates.addDelegate(object)
    }
    
    /// Remove particular delegate from multicast
    ///
    /// - Parameter object: Object
    public func removeDelegate<T: CedricDelegate>(_ object: T) {
        delegates.removeDelegate(object)
    }
    
    private func existingFileIfAvailable(forResource resource: DownloadResource) -> URL? {
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Downloads").appendingPathComponent(resource.destinationName) else { return nil }
        
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

extension Cedric: DownloadItemDelegate {
    
    internal func item(_ item: DownloadItem, didCompleteWithError error: Error?) {
        delegates.invoke({ $0.cedric(self, didCompleteWithError: error, whenDownloadingResource: item.resource) })
        remove(downloadItem: item)
    }
    
    internal func item(_ item: DownloadItem, didDownloadBytes bytes: Int64) {
        // single item progress report
        delegates.invoke({ $0.cedric(self, didDownloadBytes: bytes, fromTotalBytesExpected: item.totalBytesExpected, ofResource: item.resource) })
    }
    
    internal func item(_ item: DownloadItem, didFinishDownloadingTo location: URL) {
        delegates.invoke({ $0.cedric(self, didFinishDownloadingResource: item.resource, toLocation: location) })
        remove(downloadItem: item)
    }
    
    fileprivate func remove(downloadItem item: DownloadItem) {
        guard let index = items.index(of: item) else { return }
        let item = items[index]
        item.delegate = nil
        items.remove(at: index)
    }
}
