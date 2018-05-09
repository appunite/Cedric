//
//  CedricTests.swift
//  CedricTests
//
//  Created by Szymon Mrozek on 07.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import XCTest
@testable import Cedric

class CedricTests: XCTestCase {
    
    let resources = TestResources.standardResources
    var sut = Cedric()
    var delegate: CedricDelegateProxy?
    
    override func setUp() {
        super.setUp()
        let newProxy = CedricDelegateProxy()
        delegate = newProxy
        sut.addDelegate(newProxy)
    }
    
    override func tearDown() {
        super.tearDown()
        if let delegate = self.delegate {
            sut.removeDelegate(delegate)
        }
        delegate = nil
        try? sut.cleanDownloadsDirectory()
    }
    
    func testEnqueueSingleDownload() {
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let didStartExpectation = expectation(description: "Download did start")
        let didReportProgress = expectation(description: "Did report progress greater than 0")
        let didCompleteSuccessfuly = expectation(description: "Did complete with success")
        
        delegate?.didStartDownloadingResource = { _ in
            didStartExpectation.fulfill()
        }
        
        var progressFulfilled = false
        delegate?.didDownloadBytes = { (bytes, total, _) in
            guard progressFulfilled == false, bytes > 0, total > 0 else { return }
            didReportProgress.fulfill()
            progressFulfilled = true
        }
        
        delegate?.didCompleteWithError = { (error, _) in
            debugPrint(error ?? "No error ocurred")
            XCTAssertNil(error)
        }
        
        delegate?.didFinishDownloadingResource = { (resource, file) in
            let url = try! file.url()
            let receivedImage = UIImage(contentsOfFile: url.path)
            let originalImage = resource.localImageRepresentation
            XCTAssertNotNil(receivedImage)
            let receivedData: NSData = UIImagePNGRepresentation(receivedImage!)! as NSData
            let originalData: NSData = UIImagePNGRepresentation(originalImage)! as NSData
            XCTAssertEqual(receivedData.isEqual(originalData), true)
            didCompleteSuccessfuly.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didStartExpectation, didReportProgress, didCompleteSuccessfuly], timeout: 20.0, enforceOrder: true)
    }
    
    func testEnqueueMultipleDownloads() {
        let numberOfDownloads = 3
        let sources = Array(resources.dropFirst(numberOfDownloads))
        let didStartExpectations = sources.map { expectation(description: "Did start downloading item with id: \($0.id)") }
        let didCompleteExpectations = sources.map { expectation(description: "Did complete downloading item with id: \($0.id)") }

        delegate?.didStartDownloadingResource = { resource in
            guard let index = sources.index(where: { $0.id == resource.id }) else { return }
            didStartExpectations[index].fulfill()
        }
        
        delegate?.didFinishDownloadingResource = { (resource, file) in
            let url = try! file.url()
            guard let index = sources.index(where: { $0.id == resource.id }) else { return }
            XCTAssertNotNil(UIImage(contentsOfFile: url.path))
            didCompleteExpectations[index].fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: sources))
        wait(for: didStartExpectations + didCompleteExpectations, timeout: 20.0, enforceOrder: false)
    }
    
    func testReuseDownloadedFile() {
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let didCompleteSuccessfulyFirstTime = expectation(description: "Did complete with success for first time")
        let didCompleteSuccessfulySecondTime = expectation(description: "Did complete with success for first time")
        let didNotStartDownloadingSecondTime = expectation(description: "Did not call start downloading delegate")
        didNotStartDownloadingSecondTime.isInverted = true
        
        delegate?.didFinishDownloadingResource = { (_, file) in
            let url = try! file.url()
            if UIImage(contentsOfFile: url.path) == nil {
                XCTFail("Could not create image at path")
            }
            didCompleteSuccessfulyFirstTime.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didCompleteSuccessfulyFirstTime], timeout: 20.0, enforceOrder: true)
        
        delegate?.didStartDownloadingResource = { _ in
            // Should not be fulfilled
            didNotStartDownloadingSecondTime.fulfill()
        }
        
        delegate?.didFinishDownloadingResource = { (_, file) in
            let url = try! file.url()
            XCTAssertNotNil(UIImage(contentsOfFile: url.path))
            didCompleteSuccessfulySecondTime.fulfill()
        }

        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didNotStartDownloadingSecondTime, didCompleteSuccessfulySecondTime], timeout: 3.0, enforceOrder: false)
    }
    
    func testNewFileMode() {
        guard let res = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let resource = DownloadResource(id: res.id, source: res.source, destinationName: res.destinationName, mode: .newFile) // <~ !!!
        
        let didCompleteSuccessfulyFirstTime = expectation(description: "Did complete with success for first time")
        let didCompleteSuccessfulySecondTime = expectation(description: "Did complete with success for first time")
        let didStartForSecondTime = expectation(description: "Did call start downloading delegate for second resource")
        
        delegate?.didFinishDownloadingResource = { (_, file) in
            let url = try! file.url()
            let image = UIImage(contentsOfFile: url.path)
            XCTAssertNotNil(image)
            didCompleteSuccessfulyFirstTime.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didCompleteSuccessfulyFirstTime], timeout: 20.0, enforceOrder: true)
        
        delegate?.didStartDownloadingResource = { _ in
            didStartForSecondTime.fulfill()
        }
        
        delegate?.didFinishDownloadingResource = { (_, file) in
            let url = try! file.url()
            XCTAssertNotNil(UIImage(contentsOfFile: url.path))
            XCTAssertEqual(url.lastPathComponent, res.destinationName.replacingOccurrences(of: ".", with: "(1)."))
            didCompleteSuccessfulySecondTime.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didStartForSecondTime, didCompleteSuccessfulySecondTime], timeout: 20.0, enforceOrder: true)
    }
    
    func testTasksCancellation() {
        
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let didComplete = expectation(description: "Did not call complete successfully")
        didComplete.isInverted = true
        
        delegate?.didFinishDownloadingResource = { (_, _) in
            // should not be fulfilled
            didComplete.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        sut.cancelAllDownloads()
        
        wait(for: [didComplete], timeout: 7.0, enforceOrder: true)
    }
    
    func testDelegateRemoval() {
        
        if let delegate = self.delegate {
            sut.removeDelegate(delegate)
        }
        
        let proxies = [CedricDelegateProxy(), CedricDelegateProxy(), CedricDelegateProxy(), CedricDelegateProxy()]
        let addExpectation = expectation(description: "Did complete checking adding on Main Thread")
        let removeExpectation = expectation(description: "Did complete checking removal on Main Thread")

        proxies.forEach { sut.addDelegate($0) }

        DispatchQueue.main.async {
            XCTAssertFalse(self.sut.delegates.isEmpty)
            addExpectation.fulfill()
        }
        
        wait(for: [addExpectation], timeout: 1.0)
        
        proxies.forEach { sut.removeDelegate($0) }
        
        DispatchQueue.main.async {
            XCTAssertTrue(self.sut.delegates.isEmpty)
            removeExpectation.fulfill()
        }
        
        wait(for: [removeExpectation], timeout: 1.0)
    }
    
    func testSerialDownloading() {
        // by default Cedric is working parallely up to 25 tasks
        sut = Cedric(configuration: CedricConfiguration(mode: .serial))

        if let proxy = delegate {
            sut.addDelegate(proxy)
        }

        let didCompleteExpectations = resources.map { expectation(description: "Did complete downloading item with id: \($0.id)") }
        
        delegate?.didFinishDownloadingResource = { (resource, file) in
            let url = try! file.url()
            guard let index = self.resources.index(where: { $0.id == resource.id }) else { return }
            XCTAssertNotNil(UIImage(contentsOfFile: url.path))
            debugPrint("Did download task with id \(resource.id)")
            didCompleteExpectations[index].fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: resources))
        wait(for: didCompleteExpectations, timeout: 20.0, enforceOrder: true)
    }
    
    func testGroupedDownloadDelegate() {
        let didNotifyAboutQueueFinishing = expectation(description: "Did complete all tasks from the queue")

        // by default Cedric is working parallely up to 25 tasks
        // here we're also testing that tasks are added to queue in one moment ant only resumed
        // serially
        sut = Cedric(configuration: CedricConfiguration(mode: .serial))
        
        if let proxy = delegate {
            sut.addDelegate(proxy)
        }
        
        
        delegate?.didFinishWithMostRecentError = { error in
            XCTAssertNil(error)
            didNotifyAboutQueueFinishing.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: resources))
        wait(for: [didNotifyAboutQueueFinishing], timeout: 20.0)
    }
    
    func testFileRemoval() {
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let didCompleteSuccessfuly = expectation(description: "Did complete with success")
        let didRemoveFile = expectation(description: "Did remove file after downloading sucessfuly")
        
        delegate?.didCompleteWithError = { (error, _) in
            XCTAssertNil(error)
        }
        
        delegate?.didFinishDownloadingResource = { (resource, file) in
            let url = try! file.url()
            let receivedImage = UIImage(contentsOfFile: url.path)
            let originalImage = resource.localImageRepresentation
            XCTAssertNotNil(receivedImage)
            let receivedData: NSData = UIImagePNGRepresentation(receivedImage!)! as NSData
            let originalData: NSData = UIImagePNGRepresentation(originalImage)! as NSData
            XCTAssertEqual(receivedData.isEqual(originalData), true)
            didCompleteSuccessfuly.fulfill()

            do {
                try self.sut.remove(downloadedFile: file)
            } catch {
                XCTFail("File removal failed")
            }
            
            didRemoveFile.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        wait(for: [didCompleteSuccessfuly, didRemoveFile], timeout: 20.0, enforceOrder: true)
    }
    
    func testThrowingEnqueueError() {
        let invalidResources = [
            DownloadResource(id: "1", source: nil, destinationName: "destination")
        ]
        XCTAssertThrowsError(try sut.enqueueMultipleDownloads(forResources: invalidResources))
    }
    
    func testCancelWithId() {
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }
        
        let didComplete = expectation(description: "Did not call complete successfully")
        didComplete.isInverted = true
        
        delegate?.didFinishDownloadingResource = { (_, _) in
            // should not be fulfilled
            didComplete.fulfill()
        }
        
        XCTAssertNoThrow(try sut.enqueueDownload(forResource: resource))
        sut.cancel(downloadingResourcesWithId: resource.id)
        
        wait(for: [didComplete], timeout: 7.0, enforceOrder: true)
    }
    
    func testGettingDownloadTaskSuccessfuly() {
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: resources))
        
        guard let resource = resources.first else {
            XCTFail("No resource to download")
            return
        }

        XCTAssertNotNil(sut.downloadTask(forResourceWithId: resource.id))
        XCTAssertNotNil(sut.downloadTask(forResource: resource))
    }
    
    func testGettingTaskWhenNil() {
        XCTAssertNil(sut.downloadTask(forResource: DownloadResource(id: "not-existing", source: nil, destinationName: "")))
        XCTAssertNil(sut.downloadTask(forResourceWithId: "some-non-existing-identifier"))
    }
    
    func testIsDownloadingTrue() {
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: resources))
        XCTAssertTrue(sut.isDownloading(resourceWithId: resources[0].id))
    }
    
    func testIsDownloadingFalse()  {
        XCTAssertNoThrow(try sut.enqueueMultipleDownloads(forResources: resources))
        XCTAssertFalse(sut.isDownloading(resourceWithId: "non-existing-id"))
    }

}

class CedricDelegateProxy: CedricDelegate {
    
    var didStartDownloadingResource: ((DownloadResource) -> Void)?
    var didDownloadBytes: ((Int64, Int64, DownloadResource) -> Void)?
    var didFinishDownloadingResource: ((DownloadResource, DownloadedFile) -> Void)?
    var didCompleteWithError: ((Error?, DownloadResource) -> Void)?
    var didFinishWithMostRecentError: ((Error?) -> Void)?
    
    func cedric(_ cedric: Cedric, didStartDownloadingResource resource: DownloadResource, withTask task: URLSessionDownloadTask) {
        didStartDownloadingResource?(resource)
    }
    
    func cedric(_ cedric: Cedric, didUpdateStatusOfTask task: URLSessionDownloadTask, relatedToResource resource: DownloadResource) {
        didDownloadBytes?(task.countOfBytesReceived, task.countOfBytesExpectedToReceive, resource)
    }
    
    func cedric(_ cedric: Cedric, didCompleteWithError error: Error?, withTask task: URLSessionDownloadTask, whenDownloadingResource resource: DownloadResource) {
        didCompleteWithError?(error, resource)
    }
    
    func cedric(_ cedric: Cedric, didFinishDownloadingResource resource: DownloadResource, toFile file: DownloadedFile) {
        didFinishDownloadingResource?(resource, file)
    }
    
    func cedric(_ cedric: Cedric, didFinishWithMostRecentError error: Error?) {
        didFinishWithMostRecentError?(error)
    }
}
