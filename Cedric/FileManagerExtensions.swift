//
//  FileManagerExtensions.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

public extension FileManager {
    public static func cedricPath(forResourceWithName name: String, usingConfiguration configuration: CedricConfiguration = CedricConfiguration.default) -> URL? {
        let fileManager = DownloadsFileManager(withBaseDownloadsDirectoryName: configuration.baseDownloadsDirectoryName)
        guard let downloads = try? fileManager.downloadsDirectory() else { return nil }
        let path = downloads.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        return path
    }
}
