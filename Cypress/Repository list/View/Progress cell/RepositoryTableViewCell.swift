//
//  RepositoryTableViewCell.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/7/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

import RxSwift
import RxCocoa

class RepositoryTableViewCell: UITableViewCell, GCRepositoryDelegate {
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var repository: RepositoryViewModel? {
        didSet {
            if let progressStream = repository?.progressStream {
                progressStream
                .subscribeNext() {
                    _ in
                    self.configureView()
                }
                .addDisposableTo(disposeBag)
            }
        }
    }
    
    let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Hide progress bar
        progressView.hidden = true
        
        activeRepositoryStream
            .subscribeNext() {
                _ in
                print("calling configure view from active repo stream")
                self.configureView()
            }
            .addDisposableTo(disposeBag)
    }
    
    func configureView() {
        if let repo = self.repository {
            mainLabel!.text = repo.name
            
            mainLabel!.enabled = activeRepositoryStream.value != repo.url && (repo.progressStream.value == nil || repo.progressStream.value == 100)
            
            if activeRepositoryStream.value == repo.url {
                accessoryType = .Checkmark
            }
            else {
                accessoryType = .None
            }
            
            if let progress = repo.progressStream.value {
                if progress < 1 {
                    startProgress()
                    updateProgress(progress)
                }
                else {
                    stopProgress()
                }
            }
        }
    }
    
    func flashHighlight() {
        setHighlighted(true, animated: false)
        setHighlighted(false, animated: true)
    }
    
    func startProgress() {
        activityIndicator.startAnimating()
        progressView.hidden = false
        progressView.progress = 0
        mainLabel.enabled = false
    }
    
    func updateProgress(progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
    
    func stopProgress() {
        activityIndicator.stopAnimating()
        progressView.hidden = true
        progressView.progress = 0
        mainLabel.enabled = true
    }
}
