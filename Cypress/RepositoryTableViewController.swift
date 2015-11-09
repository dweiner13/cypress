//
//  RepoTableViewController.swift
//  Cypress
//
//  Created by Daniel A. Weiner on 11/6/15.
//  Copyright © 2015 Daniel Weiner. All rights reserved.
//

import UIKit
import GitUpKit

private let repositoryListCellIdentifier = "progressCell"

class RepositoryTableViewController: UITableViewController, GCRepositoryDelegate {
    
    var repositoryList = RepositoryList.sharedRepositoryList
    
    // memory leak?
    var selectedRepositoryCell: UITableViewCell?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "ProgressTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "progressCell")
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
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (action: UIAlertAction) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        
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
            
            let repoIndexPath = NSIndexPath(forRow: repositoryList.array.indexOf(repo)!, inSection: 0)
            scrollToAndFlashRowAtIndexPath(repoIndexPath)
        }
        catch let e as NSError {
            showErrorAlertWithMessage(e.localizedDescription)
        }
    }
    
    func confirmedCloneExistingRepositoryWithURL(url: String) {
        do {
            let repo = try Repository(url: NSURL(string: url)!, gcdelegate: self)
            self.repositoryList.addRepository(repo)
            self.tableView.reloadData()
            let repoIndexPath = NSIndexPath(forRow: repositoryList.array.indexOf(repo)!, inSection: 0)
            scrollToAndFlashRowAtIndexPath(repoIndexPath)
        }
        catch let e as NSError {
            showErrorAlertWithMessage(e.localizedDescription)
        }
    }
    
    func scrollToAndFlashRowAtIndexPath(indexPath: NSIndexPath) {
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
        let repoCell = self.tableView.cellForRowAtIndexPath(indexPath)
        repoCell?.setHighlighted(true, animated: false)
        repoCell?.setHighlighted(false, animated: true)
    }
    
    // MARK: - GCRepositoryDelegate
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.startProgress()
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.updateProgress(progress)
    }
    
    func repository(repository: GCRepository!, didFinishTransferWithURL url: NSURL!, success: Bool) {
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.stopProgress()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositoryList.array.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier, forIndexPath: indexPath) as! ProgressTableViewCell

        // Configure the cell...
        let repo = repositoryList.array[indexPath.row]
        cell.mainLabel!.text = repo.name
        if repo == AppState.sharedAppState.activeRepository {
            selectedRepositoryCell = cell
            cell.accessoryType = .Checkmark
            cell.mainLabel!.enabled = false
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        selectedRepositoryCell?.accessoryType = .None
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        AppState.sharedAppState.activeRepository = self.repositoryList.array[indexPath.row]
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if tableView.cellForRowAtIndexPath(indexPath)!.textLabel!.enabled {
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
                let repoAtIndexPath = self.repositoryList.array[indexPath.row]
                self.repositoryList.deleteRepository(repoAtIndexPath)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let repo = sender as! Repository
        let destinationViewController = segue.destinationViewController as! FileBrowserTableViewController
        destinationViewController.directory = NSURL(fileURLWithPath: repo.repository.workingDirectoryPath, isDirectory: true)
    }

}
