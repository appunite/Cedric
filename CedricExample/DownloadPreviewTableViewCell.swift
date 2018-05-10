//
//  DownloadPreviewTableViewCell.swift
//  CedricExample
//
//  Created by Szymon Mrozek on 10.05.2018.
//  Copyright © 2018 AppUnite. All rights reserved.
//

import UIKit
import Cedric

class DownloadPreviewTableViewCell: UITableViewCell {

    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var fileImageView: UIImageView!
    
    @IBOutlet weak var taskStateLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var resource: DownloadResource!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let transform = CGAffineTransform(scaleX: 1.0, y: 4.0)
        downloadProgressView.transform = transform
    }
    
    func bindWith(downloadResource resource: DownloadResource) {
        downloadProgressView.isHidden = true
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        
        self.resource = resource
        filenameLabel.text = resource.destinationName

        if let url = FileManager.cedricPath(forResourceWithName: resource.destinationName) {
            guard let image = UIImage(contentsOfFile: url.path) else { return }
            fileImageView.image = image
            taskStateLabel.text = "Completed"
        }
    }
    
    func bindWith(task: URLSessionDownloadTask) {
        
        switch task.state {
        case .canceling:
            taskStateLabel.text = "Canceling"
            downloadProgressView.isHidden = true
            activityIndicator.isHidden = true
        case .suspended:
            activityIndicator.isHidden = false
            downloadProgressView.isHidden = true
            activityIndicator.startAnimating()
            taskStateLabel.text = "Waiting for download"
        case .running:
            let progress = Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
            if progress >= 0.0 && progress <= 1.0 {
                taskStateLabel.text = "Downloading"
                activityIndicator.stopAnimating()
                activityIndicator.isHidden = true
                downloadProgressView.isHidden = false
                downloadProgressView.progress = progress
            }
        case .completed:
            activityIndicator.isHidden = true
            downloadProgressView.isHidden = true
            activityIndicator.stopAnimating()
            
            if task.countOfBytesExpectedToReceive == task.countOfBytesReceived {
                // downloaded sucessfully
                taskStateLabel.text = "Completed"
            } else {
                // error occured
                taskStateLabel.text = task.error?.localizedDescription ?? "Some error occured"
            }
        }
    }
    
    fileprivate func bindWith(downloadedFile file: DownloadedFile) {
        downloadProgressView.isHidden = true
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        
        do {
            let url = try file.url()
            guard let image = UIImage(contentsOfFile: url.path) else { return }
            fileImageView.image = image
            taskStateLabel.text = "Completed"
            downloadProgressView.isHidden = true
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        } catch let error {
            fileImageView.image = nil
            taskStateLabel.text = error.localizedDescription
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resource = nil
        fileImageView.image = nil
    }
}

extension DownloadPreviewTableViewCell: CedricDelegate {
    func cedric(_ cedric: Cedric, didStartDownloadingResource resource: DownloadResource, withTask task: URLSessionDownloadTask) {
        guard resource == self.resource else { return }
        bindWith(task: task)
    }
    
    func cedric(_ cedric: Cedric, didUpdateStatusOfTask task: URLSessionDownloadTask, relatedToResource resource: DownloadResource) {
        guard resource == self.resource else { return }
        bindWith(task: task)
    }
    
    func cedric(_ cedric: Cedric, didFinishDownloadingResource resource: DownloadResource, toFile file: DownloadedFile) {
        guard resource == self.resource else { return }
        bindWith(downloadedFile: file)
    }
}
