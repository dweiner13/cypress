//
//  MasterNavigationController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/7/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

import RxSwift

class FileBrowserNavigationController: CypressNavigationController {
    
    var progressView: UIProgressView? = nil
    var toolbarLabel: UILabel? = nil
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activeRepositoryStream
            .subscribeNext() {
                [weak self] in
                debugLog("FileBrowserNavigationController saw active repo change")
                self?.popToRootViewControllerAnimated(false)
                guard let rootViewController = self?.viewControllers[0] as? FileBrowserTableViewController else {
                    errorStream.value = NSError(domain: "Root view controller of FileBrowserNavigationController was not a FileBrowserTableViewController", code: 0, userInfo: nil)
                    return
                }
                debugLog("resetting rootViewController directory value to \($0)")
                rootViewController.directory.value = $0
            }
            .addDisposableTo(disposeBag)
        
        if let root = topViewController as? FileBrowserTableViewController {
            root.directory.value = activeRepositoryStream.value
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
