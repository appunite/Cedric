//
//  FileManagerExtensions.swift
//  Cedric
//
//  Created by Szymon Mrozek on 09.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation

extension FileManager {
    static func cedricPath(forResourceWithName name: String) -> URL? {
        guard let downloads = try? DownloadsFileManager().downloadsDirectory() else { return nil }
        let path = downloads.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        return path
    }
}
