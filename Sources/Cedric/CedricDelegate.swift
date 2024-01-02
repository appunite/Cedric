//
//  CedricDelegate.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public protocol CedricDelegate: class {
    /// Invoked when download did start for paricular resource (download task is added to the queue)
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - resource: Resource which download did start
    ///   - task: URLSessionDownloadTask for reading state and observing progress
    func cedric(_ cedric: Cedric, didStartDownloadingResource resource: DownloadResource, withTask task: URLSessionDownloadTask)
    
    /// Invoked when next chunk of data is downloaded of particular item
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - task: URLSessionDownloadTask for reading progress and state
    ///   - resource: Resource related with download
    func cedric(_ cedric: Cedric, didUpdateStatusOfTask task: URLSessionDownloadTask, relatedToResource resource: DownloadResource)
    
    /// Invoked when particular resource downloading is finished
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - resource: Resource related with download
    ///   - file: Object that contains relative path to file
    func cedric(_ cedric: Cedric, didFinishDownloadingResource resource: DownloadResource, toFile file: DownloadedFile)
    
    /// Invoked when finished and maybe error occured during downloading particular resource
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - error: Error that occured during downloading
    ///   - task: URLSessionDownloadTask for getting status / progress
    ///   - resource: Downloaded resource
    func cedric(_ cedric: Cedric, didCompleteWithError error: Error?, withTask task: URLSessionDownloadTask, whenDownloadingResource resource: DownloadResource)
    
    /// Invoked when queue finished since was empty
    ///
    /// - Parameters:
    ///   - cedric: Cedric object
    ///   - error: Optional error that occured during download, if nil job completed sucessfuly
    func cedric(_ cedric: Cedric, didFinishWithMostRecentError error: Error?)
    
}

public extension CedricDelegate {
    // Default implementations for making methods optional
    
    func cedric(_ cedric: Cedric, didStartDownloadingResource resource: DownloadResource, withTask task: URLSessionDownloadTask) {
        
    }
    
    func cedric(_ cedric: Cedric, didUpdateStatusOfTask task: URLSessionDownloadTask, relatedToResource resource: DownloadResource) {
        
    }
    
    func cedric(_ cedric: Cedric, didCompleteWithError error: Error?, withTask task: URLSessionDownloadTask, whenDownloadingResource resource: DownloadResource) {
        
    }
    
    func cedric(_ cedric: Cedric, didFinishWithMostRecentError error: Error?) {
        
    }
}
