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

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        (self.navigationController! as! MasterNavigationController).addProgressViewAndTextLabel()
        
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
        }
        catch let e as NSError {
            showErrorAlertWithMessage(e.localizedDescription)
        }
    }
    
    // MARK: - GCRepositoryDelegate
    func repository(repository: GCRepository!, willStartTransferWithURL url: NSURL!) {
//        (self.navigationController! as! MasterNavigationController).startAction(withMessage: "Cloning from \(url.host!)")
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.startProgress()
    }
    
    func repository(repository: GCRepository!, updateTransferProgress progress: Float, transferredBytes bytes: UInt) {
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.updateProgress(progress)
//        (self.navigationController! as! MasterNavigationController).updateActionProgress(progress, transferredBytes: Int(bytes))
    }
    
    func repository(repository: GCRepository!, didFinishTransferWithURL url: NSURL!, success: Bool) {
        let indexOfRepository = repositoryList.repositoryWithGCRepository(repository)!.indexInArray
        let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexOfRepository, inSection: 0)) as! ProgressTableViewCell
        cell.stopProgress()
//        (self.navigationController! as! MasterNavigationController).finishAction()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositoryList.asArray().count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(repositoryListCellIdentifier, forIndexPath: indexPath) as! ProgressTableViewCell

        // Configure the cell...
        let repo = repositoryList.asArray()[indexPath.row]
        cell.mainLabel!.text = repo.name

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
