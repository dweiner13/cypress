//
//  RepoTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

private let repositoryListCellIdentifier = "RepositoryTableViewCell"

class RepositoryTableViewController: UITableViewController, RepositoryDelegate {
    
    var repositoryList = RepositoryList.sharedRepositoryList

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "RepositoryTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: repositoryListCellIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI Actions
    @IBAction func tappedAddButton(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add a repository", message: "", preferredStyle: .ActionSheet)
        
        let createNewAction = UIAlertAction(title: "Create new repository", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            self.tappedAddNewRepositoryAction()
        })
        let cloneAction = UIAlertAction(title: "Clone from a URL", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            self.tappedCloneExistingRepositoryAction()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(createNewAction)
        alertController.addAction(cloneAction)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tappedCloneExistingRepositoryAction() {
        showTextInputPrompt("Clone Repository", message: "Enter the URL to clone from", handler: {
            self.confirmedCloneExistingRepositoryWithURL($0)
        })
    }
    
    @IBAction func tappedCancelButton(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tappedAddNewRepositoryAction() {
        showTextInputPrompt("New Repository", message: "Enter the name for the new repository", handler: {
            self.confirmedAddNewRepositoryWithName($0)
        })
    }
    
    func confirmedAddNewRepositoryWithName(name: String) {
        do {
            let repo = try Repository(name: name)
            self.repositoryList.addRepository(repo)
            self.tableView.reloadData()
            
            let repoIndexPath = indexPathForObject(repo)
            scrollToAndFlashRowAtIndexPath(repoIndexPath)
        }
        catch let e as NSError {
            showErrorAlertWithMessage(e.localizedDescription)
        }
    }
    
    func confirmedCloneExistingRepositoryWithURL(url: String) {
        do {
            let repo = try Repository(url: NSURL(string: url)!, delegate: self)
            self.repositoryList.addRepository(repo)
            self.tableView.reloadData()
            let repoIndexPath = indexPathForObject(repo)
            scrollToAndFlashRowAtIndexPath(repoIndexPath)
        }
        catch let e as NSError {
            showErrorAlertWithMessage(e.localizedDescription)
        }
    }
    
    func scrollToAndFlashRowAtIndexPath(indexPath: NSIndexPath) {
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
        let repoCell = self.tableView.cellForRowAtIndexPath(indexPath) as! RepositoryTableViewCell
        repoCell.flashHighlight()
    }
    
    func showAuthenticationPromptForURL(url: NSURL, completionHandler: (success: Bool, username: String?, password: String?) -> Void) {
        print("showing auth prompt")
        
        let alertController = UIAlertController(title: "Authenticate", message: "Please enter your username and password for \(url.host!)", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        alertController.addTextFieldWithConfigurationHandler() {
            textField -> Void in
            textField.secureTextEntry = true
        }
        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
            (action: UIAlertAction) -> Void in
            completionHandler(success: true, username: alertController.textFields![0].text!, password: alertController.textFields![1].text!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            _ in
            completionHandler(success: false, username: nil, password: nil)
        })
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - RepositoryDelegate
    func repository(repository: Repository, willStartTransferWithURL url: NSURL) {
        let cell = self.tableView.cellForRowAtIndexPath(indexPathForObject(repository)) as! RepositoryTableViewCell
        
        cell.startProgress()
    }
    
    func repository(repository: Repository, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        let cell = self.tableView.cellForRowAtIndexPath(indexPathForObject(repository)) as! RepositoryTableViewCell
        
        cell.updateProgress(progress)
    }
    
    func repository(repository: Repository, didFinishTransferWithURL url: NSURL, success: Bool) {
        let cell = self.tableView.cellForRowAtIndexPath(indexPathForObject(repository)) as! RepositoryTableViewCell
        
        cell.stopProgress()
    }
    
    func repository(repository: Repository, requiresPlainTextAuthenticationForURL url: NSURL, user: String?, callback: (success: Bool, username: String?, password: String?) -> Void) {
        self.showAuthenticationPromptForURL(url, completionHandler: callback)
    }

    // MARK: - Data source
    
    func indexPathForObject(repo: Repository) -> NSIndexPath {
        return NSIndexPath(forRow: repositoryList.indexOfRepository(repo)!, inSection: 0)
    }
    
    func objectForIndexPath(indexPath: NSIndexPath) -> Repository {
        return repositoryList.repositoryAtIndex(indexPath.row)!
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositoryList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier, forIndexPath: indexPath) as! RepositoryTableViewCell
        cell.repository = objectForIndexPath(indexPath)
        return cell
    }
    
    // MARK: - Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        AppState.sharedAppState.activeRepository = objectForIndexPath(indexPath)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if (tableView.cellForRowAtIndexPath(indexPath)! as! RepositoryTableViewCell).mainLabel!.enabled {
            return indexPath
        }
        else {
            return nil
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            askForConfirmation("Really delete?", message: "Are you sure? This can't be undone.", confirmActionTitle: "Delete", confirmedHandler: {
                let repoAtIndexPath = self.objectForIndexPath(indexPath)
                self.repositoryList.deleteRepository(repoAtIndexPath)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
    }

}
