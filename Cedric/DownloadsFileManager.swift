//
//  DownloadFileManager.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

internal protocol FileManagerType: class {
    func downloadsDirectory(create: Bool) throws -> URL
    func createUrl(forName name: String, unique: Bool) throws -> URL
    func move(fromPath source: URL, toPath destination: URL, resource: DownloadResource) throws
}

internal class DownloadsFileManager: FileManagerType {
    
    internal func downloadsDirectory(create: Bool = false) throws -> URL {
        return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: create)
            .appendingPathComponent("Downloads")
    }
    
    internal func createUrl(forName name: String, unique: Bool) throws -> URL {
        let downloads = try downloadsDirectory(create: true)
        try createDownloadsDirectoryIfNeeded()
        
        if unique {
            return try uniquePath(forName: name)
        } else {
            return downloads.appendingPathComponent(name)
        }
    }
    
    internal func move(fromPath source: URL, toPath destination: URL, resource: DownloadResource) throws {
        try FileManager.default.moveItem(at: source, to: destination)
        if let attributes = resource.attributes {
            try FileManager.default.setAttributes(attributes, ofItemAtPath: destination.path)
        }
    }
    
    internal func uniquePath(forName name: String) throws -> URL {
        let downloads = try downloadsDirectory(create: false)
        let basePath = downloads.appendingPathComponent(name)
        let fileExtension = basePath.pathExtension
        let filenameWithoutExtension: String
        if fileExtension.count > 0 {
            filenameWithoutExtension = String(name.dropLast(fileExtension.count + 1))
        } else {
            filenameWithoutExtension = name
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
    
    internal func createDownloadsDirectoryIfNeeded() throws {
        let downloads = try downloadsDirectory()
        
        var isDir: ObjCBool = true
        
        if FileManager.default.fileExists(atPath: downloads.path, isDirectory: &isDir) == false {
            try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
