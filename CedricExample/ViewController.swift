//
//  ViewController.swift
//  CedricExample
//
//  Created by Szymon Mrozek on 10.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import UIKit
import Cedric

class ViewController: UITableViewController {

    let resources: [DownloadResource] = [
        DownloadResource(id: "1", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/airplane.png")!, destinationName: "airplane.png"),
        DownloadResource(id: "2", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/arctichare.png")!, destinationName: "arctichare.png"),
        DownloadResource(id: "3", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/baboon.png")!, destinationName: "baboon.png"),
        DownloadResource(id: "4", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/boat.png")!, destinationName: "boat.png"),
        DownloadResource(id: "5", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/cat.png")!, destinationName: "cat.png"),
        DownloadResource(id: "6", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/fruits.png")!, destinationName: "fruits.png"),
        DownloadResource(id: "7", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/zelda.png")!, destinationName: "zelda.png"),
        DownloadResource(id: "8", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/serrano.png")!, destinationName: "serrano.png"),
        DownloadResource(id: "9", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/peppers.png")!, destinationName: "peppers.png"),
        DownloadResource(id: "10", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/pool.png")!, destinationName: "pool.png"),
        DownloadResource(id: "11", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/sails.png")!, destinationName: "sails.png"),
        DownloadResource(id: "12", source: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/girl.png")!, destinationName: "girl.png")
    ]
    
    lazy var cedric: Cedric = {
        let configuration = CedricConfiguration(mode: .serial)
        return Cedric(configuration: configuration)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try? cedric.cleanDownloadsDirectory()
        do {
            try cedric.enqueueMultipleDownloads(forResources: resources)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resources.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "download_preview_cell") as! DownloadPreviewTableViewCell
        let resource = resources[indexPath.row]
        cell.bindWith(downloadResource: resource)
        if let task = cedric.downloadTask(forResource: resource) {
            cell.bindWith(task: task)
        }
        cedric.addDelegate(cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
}
