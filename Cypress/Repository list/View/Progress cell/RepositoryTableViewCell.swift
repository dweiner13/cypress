//
//  RepositoryTableViewCell.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/7/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class RepositoryTableViewCell: UITableViewCell, GCRepositoryDelegate {
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var repository: Repository! {
        didSet {
            configureView()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Hide progress bar
        progressView.hidden = true
    }
    
    func configureView() {
        mainLabel!.text = repository.name
        if repository == AppState.sharedAppState.activeRepository {
            accessoryType = .Checkmark
            mainLabel!.enabled = false
        }
    }
    
    func flashHighlight() {
        setHighlighted(true, animated: false)
        setHighlighted(false, animated: true)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        if selected {
            accessoryType = .Checkmark
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
