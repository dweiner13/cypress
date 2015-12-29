//
//  CommitMasterViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/21/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit
import RxSwift
import RxCocoa

class CommitMasterViewController: CypressMasterViewController {
    
    let disposeBag = DisposeBag()

    var unstagedFilesView: ChangedFileListViewController!
    var stagedFilesView: ChangedFileListViewController!
    
    var index: Observable<ChangedFileList?>!

    let rx_viewDidAppear = Variable<Bool>(false)

    let indexChangeStream = Variable<String>("")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Changed files"
        
        unstagedFilesView = self.childViewControllers[1] as! ChangedFileListViewController
        stagedFilesView = self.childViewControllers[0] as! ChangedFileListViewController

        unstagedFilesView.masterViewController = self
        stagedFilesView.masterViewController = self

        if activeRepositoryStream.value == nil {
            performSegueWithIdentifier("showRepositoryListSegue", sender: nil)
        }

        index = combineLatest(activeRepositoryStream, rx_viewDidAppear, indexChangeStream, resultSelector: {
            [weak self] (url, _, _) -> ChangedFileList? in
            guard let repoURL = url else {
                return nil
            }
            do {
                if let changeStream = self?.indexChangeStream {
                    return try ChangedFileList(repositoryURL: repoURL, indexChangeStream: changeStream)
                }
                else {
                    return nil
                }
            }
            catch let e as NSError {
                errorStream.value = e
                return nil
            }
        })

        unstagedFilesView.files = index.map() {
            (changedFileList) -> [ChangedFileViewModel] in
            if let changedFiles = changedFileList {
                return changedFiles.unstagedChangedFiles.value
            }
            else {
                return []
            }
        }

        stagedFilesView.files = index.map() {
            (changedFileList) -> [ChangedFileViewModel] in
            if let changedFiles = changedFileList {
                return changedFiles.stagedChangedFiles.value
            }
            else {
                return []
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        let topInsets = UIEdgeInsets(top: UIApplication.sharedApplication().statusBarHidden ? 44 : 64, left: 0, bottom: 0, right: 0)
        let bottomInsets = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)

        unstagedFilesView.tableView.contentInset = topInsets
        unstagedFilesView.tableView.scrollIndicatorInsets = topInsets

        stagedFilesView.tableView.contentInset = bottomInsets
        stagedFilesView.tableView.scrollIndicatorInsets = bottomInsets
    }
    
    override func viewDidAppear(animated: Bool) {
        rx_viewDidAppear.value = animated
        
        super.viewDidAppear(animated)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("preparing for segue")
        if segue.identifier == "showFileChanges" {
            if let changedFileListVC = sender as? ChangedFileListViewController, indexPath = changedFileListVC.tableView.indexPathForSelectedRow, file = changedFileListVC.dataSource.itemAtIndexPath(indexPath) as? ChangedFileViewModel {
                guard let navController = segue.destinationViewController as? UINavigationController, diffViewController = navController.topViewController as? FileDiffViewController else {
                    errorStream.value = NSError(domain: "Could not get diff view controller in commit view controller", code: 1, userInfo: nil)
                    return
                }
                
                diffViewController.detailItem.value = file
                diffViewController.masterViewController = self
            }
        }
    }

}
