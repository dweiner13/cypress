//
//  MasterNavigationController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/7/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class MasterNavigationController: UINavigationController, GCRepositoryDelegate {
    
    var progressView: UIProgressView? = nil
    var toolbarLabel: UILabel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addProgressViewAndTextLabel() {
        // add progress view to toolbar
        let progressRect = CGRect(x: 0, y: 0, width: self.toolbar.frame.width, height: 2)
        progressView = UIProgressView(frame: progressRect)
        progressView!.progress = 0.5
        progressView!.hidden = true
        self.toolbar.addSubview(progressView!)
        
        // add label to rect
        let margin: CGFloat = 6.0
        let labelRect = CGRect(x: 6.0, y: 6.0, width: self.toolbar.frame.width - (margin * 2), height: self.toolbar.frame.height - (margin * 2))
        toolbarLabel = UILabel(frame: labelRect)
        toolbarLabel!.text = ""
        toolbarLabel!.font = UIFont.systemFontOfSize(15)
        toolbarLabel!.textAlignment = .Center
        self.toolbar.addSubview(toolbarLabel!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning	()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - GCRepositoryDelegate
    
    func startAction(withMessage message: String) {
        progressView!.hidden = false
        progressView!.progress = 0
        
        toolbarLabel!.text = message
    }
    
    func updateActionProgress(progress: Float, transferredBytes bytes: Int) {
        progressView!.progress = progress
    }
    
    func finishAction() {
        progressView!.hidden = true
        toolbarLabel!.text = ""
    }
}
