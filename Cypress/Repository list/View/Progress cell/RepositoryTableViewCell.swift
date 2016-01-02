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
            if let progressStream = repository?.cloningProgress {
                progressStream
                    .subscribe(onNext: {
                        [weak self] event in
                        switch event {
                            case .willStartTransfer:
                                self?.startProgress()
                            case .updateTransferProgress(let progress):
                                self?.updateProgress(progress)
                            default:
                                break
                        }
                    },
                    onError: {
                        [weak self] _ in
                        self?.stopProgress()
                    },
                    onCompleted: {
                        [weak self] in
                        self?.stopProgress()
                    },
                    onDisposed: nil)
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
                [weak self] _ in
                self?.configureView()
            }
            .addDisposableTo(disposeBag)
    }
    
    func configureView() {
        if let repo = self.repository {
            mainLabel.text = repo.name
            
            mainLabel.enabled = activeRepositoryStream.value != repo.url
            
            if activeRepositoryStream.value == repo.url {
                accessoryType = .Checkmark
            }
            else {
                accessoryType = .None
            }
        }
    }
    
    func flashHighlight() {
        debugLog("flashing highlight")
        setHighlighted(true, animated: false)
        let delay: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * UInt64(0.5)))
        dispatch_after(delay, dispatch_get_main_queue()) {
            () -> Void in
            self.setHighlighted(false, animated: true)
        }
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
