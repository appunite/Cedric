//
//  TestResources.swift
//  CedricTests
//
//  Created by Szymon Mrozek on 07.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import Foundation
@testable import Cedric

struct TestResources {
    
    static let standardResources: [DownloadResource] = [
        DownloadResource(id: "1", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")!, destinationName: "airplane.png"),
        DownloadResource(id: "2", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/arctichare.png")!, destinationName: "arctichare.png"),
        DownloadResource(id: "3", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/baboon.png")!, destinationName: "baboon.png"),
        DownloadResource(id: "4", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/boat.png")!, destinationName: "boat.png"),
        DownloadResource(id: "5", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/cat.png")!, destinationName: "cat.png"),
        DownloadResource(id: "6", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/fruits.png")!, destinationName: "fruits.png")
    ]
}
