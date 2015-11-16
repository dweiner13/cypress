//
//  MasterNavigationController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/7/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

class FileBrowserNavigationController: CypressNavigationController {
    
    var progressView: UIProgressView? = nil
    var toolbarLabel: UILabel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserverForName(AppState.Notification.activeRepositoryChanged.rawValue, object: nil, queue: nil, usingBlock: {
            notification in
            print("received notification: \(notification.name)")
            self.popToRootViewControllerAnimated(false)
            let rootViewController = self.viewControllers[0] as! FileBrowserTableViewController
            rootViewController.directoryURL = nil
            rootViewController.tableView.reloadData()
        })
        
        if let root = topViewController as? FileBrowserTableViewController {
            root.directoryURL = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
}
